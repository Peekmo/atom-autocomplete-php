<?php

class ClassesProvider extends Tools implements ProviderInterface
{
    /**
     * Execute the command
     * @param  array  $args Arguments gived to the command
     * @return array Response
     */
    public function execute($args = array())
    {
        $classes = array(
            'names'     => array(),
            'methods'   => array()
        );

        $mapping = array();
        foreach ($this->getClassMap(true) as $class => $filePath) {
            $ret = exec(sprintf('%s %s %s --class %s',
                escapeshellarg(Config::get('php')),
                escapeshellarg(__DIR__ . '/../parser.php'),
                escapeshellarg(Config::get('projectPath')),
                escapeshellarg($class)
            ));

            if (false === $value = json_decode($ret, true)) {
                continue;
            }

            $mapping[$class] = array(
                'file'     => $filePath,
                'methods'  => $value
            );

            $classes['names'][] = $class;
            $classes['methods'][$class] = $value;
        }

        return $classes;
    }
}

?>
