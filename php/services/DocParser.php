<?php

/**
 * Parser for PHP documentation
 */
class DocParser
{
    const RETURN_VALUE = '@return';
    const PARAM_TYPE = '@param';
    const VAR_TYPE = '@var';
    const DEPRECATED = '@deprecated';
    const THROWS = '@throws';
    const DESCRIPTION = 'description';

    /**
     * Get data for the given class
     * @param  string $className Full class namespace
     * @param  string $type      Type searched (method, property)
     * @param  string $name      Name of the method or property
     * @param  array  $filters   Fields to get
     * @return array
     */
    public function get($className, $type, $name, $filters)
    {
        switch($type) {
            case 'method':
                $reflection = new ReflectionMethod($className, $name);
                break;

            case 'property':
                $reflection = new ReflectionProperty($className, $name);
                break;

            default:
                throw new \Exception(sprintf('Unknown type %s', $type));
        }

        $comment = $reflection->getDocComment();
        return $this->parse($comment, $filters);
    }

    /**
     * Parse the comment string to get its elements
     * @param  string $comment Comment to parse
     * @param  array  $filters Elements to search (@see consts)
     * @return array
     */
    public function parse($comment, $filters)
    {
        $comment = str_replace(array('*', '/'), '', $comment);
        $escapedComment = str_replace(array('\n', '\r\n', PHP_EOL), ' ', $comment);
        $linedComment = str_replace(array('\n', '\r\n', PHP_EOL), '$@$', $comment);

        $result = array();
        foreach($filters as $filter) {
            switch ($filter) {
                case self::VAR_TYPE:
                    $var = $this->parseVar($escapedComment);
                    if ($var) {
                        $result['var'] = $var;
                    }
                    break;
                case self::RETURN_VALUE:
                    $return = $this->parseVar($escapedComment, self::RETURN_VALUE);
                    if ($return) {
                        $result['return'] = $return;
                    }
                    break;
                case self::PARAM_TYPE:
                    $res = $escapedComment;
                    $result['params'] = array();
                    while (null !== $ret = $this->parseParams($res)) {
                        $result['params'][$ret['name']] = $ret['type'];
                        $res = $ret['string'];
                    }

                    break;
                case self::THROWS:
                    $res = $escapedComment;
                    $result['throws'] = array();

                    while (null !== $ret = $this->parseThrows($res)) {
                        $res = $ret['string'];
                        $result['throws'][$ret['type']] = $ret['description'];
                    }

                    break;
                case self::DESCRIPTION:
                    $desc = $this->parseDescription($linedComment);
                    $result['descriptions'] = $desc;
                    break;

                case self::DEPRECATED:
                    $result['deprecated'] = (false !== strpos($escapedComment, self::DEPRECATED));
                    break;

                default:
                    break;
            }
        }

        return $result;
    }

    /**
     * Search for the long and short description on a method or attribute
     *
     * @param string $comment Comment
     *
     * @return array ('short' => short description, 'long' => long description)
     */
    private function parseDescription($comment)
    {
        $result = array(
            'short' => '',
            'long'  => ''
        );

        $lines = explode('$@$', $comment);

        $short = true;
        foreach ($lines as $line) {
            if (
                false !== strpos($line, self::VAR_TYPE)
                || false !== strpos($line, self::THROWS)
                || false !== strpos($line, self::PARAM_TYPE)
                || false !== strpos($line, self::RETURN_VALUE)
            ) {
                return $result;
            }

            if (trim($line) == '' && $result['short'] != '') {
                $short = false;
            } else {
                if ($short) {
                    $result['short'] = $result['short'] != ''
                        ? $result['short'] . PHP_EOL . trim($line)
                        : trim($line)
                    ;
                } else {
                    $result['long'] = $result['long'] != ''
                        ? $result['long'] . PHP_EOL . trim($line)
                        : trim($line)
                    ;
                }
            }
        }

        return $result;
    }

    /**
     * Search for a $type in the comment and its value
     * @param string $string comment string
     * @param string $type   annotation type searched
     * @return string
     */
    private function parseVar($string, $type = self::VAR_TYPE)
    {
        if (false === $pos = strpos($string, $type)) {
            return null;
        }

        $varSubstring = substr(
            $string,
            $pos + strlen($type),
            strlen($string)-1
        );
        $varSubstring = trim($varSubstring);

        if (empty($varSubstring)) {
            return null;
        }

        $elements = explode(' ', $varSubstring);
        return $elements[0];
    }

    /**
     * Search all @param annotations in the given string
     * @param string $string String comment to search
     * @return string
     */
    private function parseParams($string)
    {
        if (false === $pos = strpos($string, self::PARAM_TYPE)) {
            return null;
        }

        $paramSubstring = substr(
            $string,
            $pos + strlen(self::PARAM_TYPE),
            strlen($string)-1
        );
        $paramSubstring = trim($paramSubstring);

        if (empty($paramSubstring)) {
            return null;
        }

        $elements = explode(' ', $paramSubstring);
        if (count($elements) < 2) {
            return null;
        }

        return array(
            'name' => $elements[1],
            'type' => $elements[0],
            'string' => $paramSubstring
        );
    }

    /**
     * Search all @throws annotations in the given string
     * @param string $string String comment to search
     * @return string
     */
    private function parseThrows($string)
    {
        if (false === $pos = strpos($string, self::THROWS)) {
            return null;
        }

        $throwsSubstring = substr(
            $string,
            $pos + strlen(self::THROWS),
            strlen($string)-1
        );
        $throwsSubstring = trim($throwsSubstring);

        if (empty($throwsSubstring)) {
            return null;
        }

        // Make sure we don't use the rest of the docblock as description of the exception type.
        // NOTE: The next tag detection can probably be improved at a later stage.
        $substringToExplode = $throwsSubstring;
        $nextTag = strpos($throwsSubstring, '@');

        if ($nextTag !== false) {
            $substringToExplode = substr($throwsSubstring, 0, $nextTag);
        }

        $elements = explode(' ', $substringToExplode);

        return array(
            'type' => trim(array_shift($elements)),
            'description' => !empty($elements) ? trim(implode(' ', $elements)) : null,
            'string' => $throwsSubstring
        );
    }
}
