# atom-autocomplete-php

[![Join the chat at https://gitter.im/Peekmo/atom-autocomplete-php](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/Peekmo/atom-autocomplete-php?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

atom-autocomplete-php provides autocompletion for the PHP language for projects that use Composer for dependency management. What cool things can you expect?
  * Autocompletion of class members, built-in constants, built-in PHP functions, ...
  * Autocompletion of class names and automatic adding of `use` statements where needed.
  * Alt-clicking class members, class names, etc. to navigate to their definition.
  * Annotations in the gutter for methods that are overrides or interface implementations.
  * Tooltips for methods, classes, etc. that display information about the item itself.
  * IntellJ-style variable annotations `/** @var MyType $var */` as well as `/** @var $var MyType */`.
  * Shortcut variable annotations (must appear right above the respective variable) `/** @var MyType */`.
  * ...

## What do I need to do to make it work?
Currently the following limitations or restrictions are present:
  * You must use [Composer](https://getcomposer.org/) for dependency management.
  * You must follow the PSR standards (for the names of classes, methods, namespacing, etc.).
  * You must write proper docblocks for your methods. There currently is no standard around this, but we try to follow the draft PSR-5 standard (which, in turn, is mostly inspired by phpDocumentor's implementation). Minimum requirements for proper autocompletion:
    * `@return` statements for functions and methods.
    * `@param` statements for functions and methods.
    * `@var` statements for properties in classes.
    * (Type hints in functions and methods will also be checked.)

Some features may or may not work outside these restrictions. Composer is primarily used for its classmap, to fetch a list of classes that are present in your codebase. Reflection is used to fetch information about classes.

The package also requires a one time setup, To configure the plugin, click on "package" in your preferences, and select "settings" on atom-autocomplete-php plugin.

- **Command to use composer** : it's highly recommended to write here the full path to your composer.phar bin. E.G on unix systems, it could be /usr/local/bin/composer. Using an alias is not recommended at all!
- **Command php** : Command to execute PHP cli in your console. (php by default on unix systems). If it doesn't work, put here the full path to your PHP bin.
- **Autoload file** : Write here, a coma separated list of all the different path to the autoload files. By default, it's "vendor/autoload.php" for composer projects ;)
- **Classmap files** : All paths to PHP files that returns an array of "className" => "fullPath to the file where the class is located". The default one for composer is vendor/composer/autoload_classmap.php

You can test your configuration by using a command (cmd - shift - p) : ```Atom Autocomplete Php : Configuration```

### Linux
![Configuration](http://i.imgur.com/LYBcaHE.png)
&nbsp;

### Windows (WAMP and ComposerSetup)
![Settings](http://i.imgur.com/hY5ypG2.png)
&nbsp;

## Framework integration
  * [Symfony2 plugin](https://github.com/Peekmo/atom-symfony2)

## What Does Not Work?
  * Most of the issue reports indicate things that are missing, but autocompletion should be working fairly well in general.

### Won't Fix (For Now)
  * "Go to definition" will take you to the incorrect location if a class is using a method with the exact same name as one in its own direct traits. You will be taken to the trait method instead of the class method (the latter should take precedence). See also issue #177.
  * `static` and `self` behave mostly like `$this` and can access non-static methods when used in non-static contexts. See also issue #101.

## What's Next & Contributing
Keep in mind that this plugin is under active development. If you find a bug, please, open an issue with more information on how to reproduce. Feel free to contribute ;)

![A screenshot of your spankin' package](https://f.cloud.github.com/assets/69169/2290250/c35d867a-a017-11e3-86be-cd7c5bf3ff9b.gif)
