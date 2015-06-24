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
        $autoLoadDir = $args[0];
        $loader = require $autoLoadDir . '/autoload.php';
        return $loader->getClassMap();
    }
}

?>
