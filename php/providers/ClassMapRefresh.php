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
            foreach ($this->getClassMap(true) as $class => $filePath) {
                if ($value = $this->buildIndexClass($class)) {
                    $index['mapping'][$class] = $value;
                }
            }
        }

        file_put_contents($file, json_encode($index));

        return array();
    }
}
