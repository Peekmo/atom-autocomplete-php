<?php

namespace Peekmo\AtomAutocompletePhp;

class FileParser
{
    const USE_PATTERN = '/(?:use)(?:[^\w\\\\])([\w\\\\]+)(?![\w\\\\])(?:(?:[ ]+as[ ]+)(\w+))?(?:;)/';
    const NAMESPACE_PATTERN = '/(?:namespace)(?:[^\w\\\\])([\w\\\\]+)(?![\w\\\\])(?:;)/';

    /**
     * @var string Handler to the file
     */
    protected $file;

    /**
     * Open the given file
     * @param string $filePath Path to the PHP file
     */
    public function __construct($filePath)
    {
        if (!file_exists($filePath)) {
            throw new \Exception(sprintf('File %s not found', $filePath));
        }

        $this->file = fopen($filePath, 'r');
    }

    /**
     * Get the full namespace of the given class
     * @param string $className
     * @param bool   $found     Set to true if use founded
     * @return string
     */
    public function getCompleteNamespace($className, &$found)
    {
        $line = '';
        $found = false;
        $matches = array();
        $fullClass = $className;

        while (!feof($this->file) && !$this->containsStopMarker($line)) {
            $line = fgets($this->file);

            if (preg_match(self::NAMESPACE_PATTERN, $line, $matches) === 1) {
                // The class name is relative to the namespace of the class it is contained in, unless a use statement
                // says otherwise.
                $fullClass = $matches[1] . '\\' . $className;
            }

            if (preg_match(self::USE_PATTERN, $line, $matches) === 1) {
                $fullImportNameParts = explode('\\', $matches[1]);
                $fullClassNameParts = explode('\\', $className);

                // Is this an aliased import?
                if (isset($matches[2])) {
                    if ($matches[2] === $className) {
                        $found = true;
                        return $matches[1];
                    } /*elseif ($matches[2] == substr($className, 0, strlen($matches[2]))) {
                        $found = true;
                        return $matches[1] . '\\' . substr($className, substr($matches[1]));
                    }*/
                } elseif (substr($matches[1], -strlen($className)) === $className) {
                    $isOnlyPartOfClassName = false;

                    // If we're looking for the class name 'Mailer', a use statement such as "use \My_Mailer" should not
                    // pass the check.
                    if (strlen($matches[1]) > strlen($className)) {
                        $characterBeforeClassName = substr($matches[1], -strlen($className) - 1, 1);

                        if ($characterBeforeClassName !== "\\" && $characterBeforeClassName !== ' ') {
                            $isOnlyPartOfClassName = true;
                        }
                    }

                    if (!$isOnlyPartOfClassName) {
                        $found = true;
                        return $matches[1];
                    }
                }
            }
        }

        return $fullClass;
    }

    /**
     * Returns a boolean indicating if the specified line contains a stop marker.
     *
     * @param string $line
     *
     * @return bool
     */
    protected function containsStopMarker($line)
    {
        $line = trim($line);

        return (
            strpos($line, 'abstract')  === 0 ||
            strpos($line, 'class')     === 0 ||
            strpos($line, 'interface') === 0 ||
            strpos($line, 'trait')     === 0
        );
    }

    public function __destruct()
    {
        fclose($this->file);
    }
}

?>
