<?php

class AutocompleteProvider extends Tools implements ProviderInterface
{
    /**
     * Execute the command
     * @param  array  $args Arguments gived to the command
     * @return array Response
     */
    public function execute($args = array())
    {
        $class = $args[0];
        $type  = $args[1];
        $name  = $args[2];

        $data = array(
            'class'  => $class,
            'names'  => array(),
            'values' => array()
        );
    }
}
