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
     * Retrieves the full namespace of the given class, based on the namespace and use statements in the current file.
     *
     * @param string $className
     * @param bool   $found     Set to true if an explicit use statement was found. If false, the full class name could,
     *                          for example, have been built using the namespace of the current file.
     *
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
            } elseif (preg_match(self::USE_PATTERN, $line, $matches) === 1) {
                $classNameParts = explode('\\', $className);
                $importNameParts = explode('\\', $matches[1]);

                $isAliasedImport = isset($matches[2]);

                if (($isAliasedImport && $matches[2] === $classNameParts[0]) ||
                    (!$isAliasedImport && $importNameParts[count($importNameParts) - 1] === $classNameParts[0])) {
                    $found = true;

                    $fullClass = $matches[1];

                    array_shift($classNameParts);

                    if (!empty($classNameParts)) {
                        $fullClass .= '\\' . implode('\\', $classNameParts);
                    }

                    break;
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
