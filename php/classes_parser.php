<?php

/**
 * Get classes from the given file
 * Code from composer (https://github.com/composer/composer/blob/master/src/Composer/Autoload/ClassMapGenerator.php)
 * @return array
 */
function parse_php_file($path) {
    $traits = version_compare(PHP_VERSION, '5.4', '<') ? '' : '|trait';
    try {
        $contents = @php_strip_whitespace($path);
        if (!$contents) {
            if (!file_exists($path)) {
                throw new \Exception('File does not exist');
            }
            if (!is_readable($path)) {
                throw new \Exception('File is not readable');
            }
        }
    } catch (\Exception $e) {
        throw new \RuntimeException('Could not scan for classes inside '.$path.": \n".$e->getMessage(), 0, $e);
    }

    // return early if there is no chance of matching anything in this file
    if (!preg_match('{\b(?:class|interface'.$traits.')\s}i', $contents)) {
        return array(
            'classes'   => array(),
            'functions' => array()
        );
    }

    // strip heredocs/nowdocs
    $contents = preg_replace('{<<<\s*(\'?)(\w+)\\1(?:\r\n|\n|\r)(?:.*?)(?:\r\n|\n|\r)\\2(?=\r\n|\n|\r|;)}s', 'null', $contents);
    // strip strings
    $contents = preg_replace('{"[^"\\\\]*(\\\\.[^"\\\\]*)*"|\'[^\'\\\\]*(\\\\.[^\'\\\\]*)*\'}s', 'null', $contents);
    // strip leading non-php code if needed
    if (substr($contents, 0, 2) !== '<?') {
        $contents = preg_replace('{^.+?<\?}s', '<?', $contents, 1, $replacements);
        if ($replacements === 0) {
            return array();
        }
    }
    // strip non-php blocks in the file
    $contents = preg_replace('{\?>.+<\?}s', '?><?', $contents);
    // strip trailing non-php code if needed
    $pos = strrpos($contents, '?>');
    if (false !== $pos && false === strpos(substr($contents, $pos), '<?')) {
        $contents = substr($contents, 0, $pos);
    }
    preg_match_all('{
        (?:
        \b(?<![\$:>])(?P<type>class|interface'.$traits.') \s+ (?P<name>[a-zA-Z_\x7f-\xff:][a-zA-Z0-9_\x7f-\xff:\-]*)
        | \b(?<![\$:>])(?P<ns>namespace) (?P<nsname>\s+[a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*(?:\s*\\\\\s*[a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*)*)? \s*[\{;]
            )
        }ix', $contents, $matches);
        $classes = array();
        $namespace = '';
        for ($i = 0, $len = count($matches['type']); $i < $len; $i++) {
            if (!empty($matches['ns'][$i])) {
                $namespace = str_replace(array(' ', "\t", "\r", "\n"), '', $matches['nsname'][$i]) . '\\';
            } else {
                $name = $matches['name'][$i];
                if ($name[0] === ':') {
                    // This is an XHP class, https://github.com/facebook/xhp
                    $name = 'xhp'.substr(str_replace(array('-', ':'), array('_', '__'), $name), 1);
                }
                $classes[] = ltrim($namespace . $name, '\\');
            }
        }

    return array(
        'classes'   => $classes,
        'functions' => array()
    );
}
