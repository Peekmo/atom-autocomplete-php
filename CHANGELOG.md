## 0.18.0
* Plugin configuration is now more interactive. If there's an error, you'll know it without doing the command

## 0.17.0
* [internal] String parameters are keep in autocomplete in order to be able to change the function return (needed for symfony2 support)

## 0.16.0
* Support for external services (see atom-symfony2) package
* Doc refactoring

## 0.15.0
* Fail message when saving are now just in developer console by default (you can change this in settings)
* A progress bar appears in status bar when there's a classes' indexing in progress
* Uses are now ordered. You can even have new line between them (see plugin settings)
* Annotations on class properties

## 0.14.0
* Support configuration checking on Windows
* Lot of code refactoring (many bug resolved, but perhaps some new :()
* Tooltips on classes, interfaces
* Constants provider
* Autocomplete from type hints in closures

## 0.13.0
* Custom tooltip management (does not rely on atom's one anymore)

## 0.12.0
* Support for {@inheritdoc} && {@inheritDoc} as the only one comment (symfony2 style)
* Bugfixes for non PHP projects
* Bugfixes on Docblock parser

## 0.11.0
* Bugfixes on Goto
* Major refactor in the code of the plugin itself

## 0.10.0
* Autocomplete in catch() {} #91
* Comments "@var $var Class" now supported for completion

## 0.9.0
* Many bugfixes and improvements for tooltips (from @hotoiledgoblinsack)
* Basic autocomplete on "new" keyword (e.g :
    $x = new \DateTime();
    $x->{autocomplete}
)

## 0.8.0
* Tooltips on methods and attributes
* Strikethrough style to deprecated methods

## 0.7.0
* Goto class properties
* Goto bugfixes

## 0.6.0
* Goto command on first level of methods, and classes (#42 by @CWDN)
* Fix namespace on the same line as PHP tag

## 0.5.0
* Support for Windows

## 0.4.0
* Completion on local variables
* Bug fixes

## 0.3.0
* Completion $this on multiline
* Bug fixes

## 0.2.0
* Completion on parent::
* Completion on self::
* Bug fixes

## 0.1.0
* Completion on classNames
* Completion on $this->
* Completion on static methods
* Namespace management
