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
            'functions' => array()
        );

        foreach ($this->getClassNames() as $class) {
            $ret = exec(sprintf('%s %s/../parser.php %s --class %s',
                Config::get('php'),
                __DIR__,
                Config::get('projectPath'),
                str_replace('\\', '\\\\', $class)
            ));

            if (false === $value = json_decode($ret, true)) {
                continue;
            }

            $classes['names'][] = $class;
            $classes['methods'][$class] = $value;
        }

        return $classes;
    }
}

?>
