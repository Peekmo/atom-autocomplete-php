<?php

class AutoloadClassMap extends Tools implements ProviderInterface
{
    /**
     * Execute the command
     * @param  array  $args Arguments gived to the command
     * @return array Response
     */
    public function execute($args = array())
    {
        $classmap = require Config::get('classmap_file');
        return $classmap;
    }
}

?>
