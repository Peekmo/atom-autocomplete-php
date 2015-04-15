<?php

/**
 * Parser for PHP documentation
 */
class DocParser
{
    const RETURN_VALUE = '@return';
    const PARAM_TYPE = '@param';
    const VAR_TYPE = '@var';

    /**
     * Comment from the method
     * @var string
     */
    private $comment;

    /**
     * Constructor
     * @param string $comment Comment to search in
     */
    public function __construct($comment)
    {
        $this->comment = $comment;
    }

    /**
     * Parse the comment string to get its elements
     * @param  array  $filters Elements to search (@see consts)
     * @return array
     */
    public function parse($filters)
    {
        $comment = str_replace(array('*', '/'), '', $this->comment);
        $comment = str_replace(array('\n', '\r\n', PHP_EOL), ' ', $comment);

        $result = array();
        foreach($filters as $filter) {
            switch ($filter) {
                case self::VAR_TYPE:
                    $var = $this->parseVar($comment);
                    if ($var) {
                        $result['var'] = $var;
                    }
                    break;
                case self::RETURN_VALUE:
                    $return = $this->parseVar($comment, self::RETURN_VALUE);
                    if ($return) {
                        $result['return'] = $return;
                    }
                    break;
                case self::PARAM_TYPE:
                    $res = $comment;
                    $result['params'] = array();
                    while (null !== $ret = $this->parseParams($res)) {
                        $result['params'][$ret['name']] = $ret['type'];
                        $res = $ret['string'];
                    }

                    break;
                default:
                    break;
            }
        }

        die(var_dump($result));
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
}
