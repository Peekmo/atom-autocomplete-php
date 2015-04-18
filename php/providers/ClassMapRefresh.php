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
        $this->getClassMap(true);

        return array();
    }
}
