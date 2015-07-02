<?php

/**
 * Autocompletion for "parent"
 */
class ParentProvider extends Tools implements ProviderInterface
{
    /**
     * Execute the command
     * @param  array  $args Arguments gived to the command
     * @return array Response
     */
    public function execute($args = array())
    {
        $class = $args[0];

         // Get the reflection to find the parent
        try {
            $reflection = new ReflectionClass($class);
        } catch (Exception $e) {
            return $this->getClassMetadata('WhatTheHeeeeeeeeell');
        }

         // If not parent, no result
        if (!$parent = $reflection->getParentClass()) {
            return $this->getClassMetadata('WhatTheHeeeeeeeeell');
        }

        return $this->getClassMetadata($parent->getName());
    }
}
