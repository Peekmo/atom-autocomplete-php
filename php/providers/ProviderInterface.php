<?php

namespace Peekmo\AtomAutocompletePhp;

interface ProviderInterface
{
    /**
     * Execute the command
     * @param  array  $args Arguments gived to the command
     * @return array Response
     */
    public function execute($args = array());
}
