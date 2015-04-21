<?php

class ClassMapRefresh extends Tools implements ProviderInterface
{
    /**
     * Execute the command
     * @param  array  $args Arguments gived to the command
     * @return array Response
     */
    public function execute($args = array())
    {
        $classMap = $this->getClassMap(true);

        $fileExists = false;

        // If we specified a file
        if ($file = $args[0]) {
            if (file_exists(Config::get('indexClasses'))) {
                $fileExists = true;

                $index = json_decode(file_get_contents(Config::get('indexClasses')));
                if (false !== $class = array_search($file, $classMap)) {
                    if (isset($index['mapping'][$class])) {
                        unset($index['mapping'][$class]);
                    }

                    if (false !== $key = array_search($class, $index['autocomplete'])) {
                        unset($index['autocomplete'][$key]);
                    }

                    if ($value = $this->buildIndexClass($class)) {
                        $index['mapping'][$class] = $value;
                        $index['autocomplete'][] = $class;
                    }
                }
            }
        }
        // Otherwise, full index
        else if (!$fileExists) {
            // Autoload classes
            foreach ($this->getClassMap(true) as $class => $filePath) {
                if ($value = $this->buildIndexClass($class)) {
                    $index['mapping'][$class] = $value;
                    $index['autocomplete'][] = $class;
                }
            }

            // Internal classes
            foreach (get_declared_classes() as $class) {
                $provider = new ClassProvider();

                if ($value = $provider->execute(array($class))) {
                    $index['mapping'][$class] = $value;
                    $index['autocomplete'][] = $class;
                }
            }
        }

        file_put_contents(Config::get('indexClasses'), json_encode($index));

        return array();
    }

    protected function buildIndexClass($class)
    {
        $ret = exec(sprintf('%s %s/../parser.php %s --class %s',
            Config::get('php'),
            __DIR__,
            Config::get('projectPath'),
            str_replace('\\', '\\\\', $class)
        ));

        if (false === $value = json_decode($ret, true)) {
            return null;
        }

        return array(
            'file'     => $filePath,
            'methods'  => $value
        );
    }
}
