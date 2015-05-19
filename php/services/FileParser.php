<?php

class FileParser
{
    const USE_PATTERN = '/(?:use)(?:[^\w\\])([\w\\]+)(?![\w\\])(?:(?:[ ]+as[ ]+)(\w+))?(?:;)/g';

    /**
     * @var string Content of the file
     */
    protected $content;

    /**
     * Open the given file
     * @param string $filePath Path to the PHP file
     */
    public function __construct($filePath)
    {
        if (!file_exists($filePath)) {
            throw new \Exception(sprintf('File %s not found', $filePath));
        }

        $this->content = file_get_contents($filePath);
    }

    /**
     * Get the full namespace of the given class
     * @param string $className
     * @return string
     */
    public function getCompleteNamespace($className)
    {
        $lines = explode('\n', $this->content);

        foreach ($lines as $line) {
            $matches = array();
            preg_match(self::USE_PATTERN, $line, $matches);

            if (!empty($matches)) {
                if (isset($matches[2]) && $matches[2] == $className) {
                    return $matches[1];
                } else if (substr($matches[1], strlen($matches[1]) - strlen($className)) == $className) {
                    return $matches[1];
                }
            }

            // Stop if declaration of a class
            if (strpos($line, 'class') === 0) {
                return $className;
            }
        }

        return $className;
    }
}

?>
