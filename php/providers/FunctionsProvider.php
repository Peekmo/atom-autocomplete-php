<?php

namespace Peekmo\AtomAutocompletePhp;

class FunctionsProvider extends Tools implements ProviderInterface
{
    /**
     * Execute the command
     * @param  array  $args Arguments gived to the command
     * @return array Response
     */
    public function execute($args = array())
    {
        $this->includeOldDrupal();

        $functions = array(
            'names'  => array(),
            'values' => array()
        );

        $allFunctions = get_defined_functions();

        foreach ($allFunctions as $type => $currentFunctions) {
            foreach ($currentFunctions as $functionName) {
                try {
                    $function = new \ReflectionFunction($functionName);
                } catch (\Exception $e) {
                    continue;
                }

                $functions['names'][] = $function->getName();

                $args = $this->getMethodArguments($function);

                $functions['values'][$function->getName()] = array(
                    array(
                        'isInternal' => $type == 'internal',
                        'isMethod'   => true,
                        'isFunction' => true,
                        'args'       => $args,
                        'declaringStructure' => [
                            'filename' => $function->getFileName(),
                        ],
                        'startLine' => $function->getStartLine()
                    )
                );
            }
        }

        return $functions;
    }
}
