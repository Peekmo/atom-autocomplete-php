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
        $found = false;

        $fullClass = $className;

        if (count(explode('\\', $className)) > 1) {
            return $className;
        }

        while (!feof($this->file)) {
            $line = fgets($this->file);

              // Namespace
            $matches = array();
            preg_match(self::NAMESPACE_PATTERN, $line, $matches);

            if (!empty($matches)) {
                $fullClass = $matches[1] . '\\' . $className;
            }

            $matches = array();
            preg_match(self::USE_PATTERN, $line, $matches);

            if (!empty($matches)) {
                if (isset($matches[2]) && $matches[2] == $className) {
                    $found = true;
                    return $matches[1];
                } else if (substr($matches[1], strlen($matches[1]) - strlen($className)) == $className) {
                    $found = true;
                    return $matches[1];
                }
            }

            // Stop if declaration of a class
            if (strpos(trim($line), 'class') === 0 || strpos(trim($line), 'abstract') === 0) {
                return $fullClass;
            }
        }

        return $fullClass;
    }

    public function __destruct()
    {
        fclose($this->file);
    }
}

?>
