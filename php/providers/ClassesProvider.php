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
            try {
                $reflection = new ReflectionClass($class);
            } catch (Exception $e) {
                continue;
            }

            $ctor = $reflection->getConstructor();

            $args = array();
            if (!is_null($ctor)) {
                $args = $this->getMethodArguments($ctor);
            }

            $classes['names'][] = $class;
            $classes['methods'][$class] = array(
                'constructor' => array(
                    'has'  => !is_null($ctor),
                    'args' => $args
                )
            );
        }

        return $classes;
    }
}

?>
