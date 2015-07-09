# atom-autocomplete-php package

[![Join the chat at https://gitter.im/Peekmo/atom-autocomplete-php](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/Peekmo/atom-autocomplete-php?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

/!\ The plugin has not been tested on Windows. Contribution is welcome to make it works on this platform.

# What is done ?

This plugin provide those amazing features :
- Autocompletion on class names with use auto added
- Autocompletion on class properties and methods. If your PHP doc is right, you should have autocompletion on X levels (e.g : $this->doctrine->getRepo...)
- Autocompletion on variable in function (not work always, see **autocompletion** section for more informations)
- Local function variables autocompletion
- Writing namespace in top of the file (ctrl - alt - n)
- Autocompletion on PHP internal functions
- Autocompletion on ```self::``` and ```Class::``` (statics)

# How to make it works ?

Secondly, only the PHP projects that use [composer](https://getcomposer.org/) to manage their autoload and dependencies are fully supported. In fact, to give you the autocompletion, the plugin use composer's classmap. So only a project with composer will have all the features. (Some are available without, but not the most interesting ;)

Finally, your project must follow the PSR norm, some weird things could happen otherwise.

# Settings

To configure the plugin, click on "package" in your preferences, and select "settings" on atom-autocomplete-php plugin.

![Configuration](http://i.imgur.com/LYBcaHE.png)

# Options :
- **Command to use composer** : it's highly recommended to write here the full path to your composer.phar bin. E.G on unix systems, it could be /usr/local/bin/composer. Using an alias is not recommended at all !
- **Command php** : Command to execute PHP cli in your console. (php by default on unix systems). If it doesn't work, put here the full path to your PHP bin.
- **Autoload file** : Write here, a coma separated list of all the different path to the autoload files. By default, it's "vendor/autoload.php" for composer projects ;)
- **Classmap files** : All paths to PHP files that returns an array of "className" => "fullPath to the file where the class is located". The default one for composer is vendor/composer/autoload_classmap.php

# Autocompletion

### The rules
To have a nice autocompletion, the plugin parse the PHPDoc of your files. So, nicer is your doc, nicer will be the completion.

The rules :
- On class properties, the **@var** is parsed
```php
/**
 * @var ReportPdf
 */
private $reportPdf;
```

- On methods, the **@param** and **@return** is parsed
```php
/**
 * MyDoc
 *
 * @param  Report $report
 *
 * @return Report
 */
public function generate(Report $report)
```

- In the code, if you don't have autocompletion, you can had a comment **just before the line** with a **@var** definition
```php
/** @var Report */
$report = parent::getReport();
$report->{autocompletion}
```

Note : For all those patterns, you'll have to add the use to the class on top of the file, or you can put the full namespace instead of just the class name

### On what does it works ?

- variables with hint in function parameters (eg : $report below)
```
public function generate(Report $report)
```
- on **$this->**
- on variables that are documented with @var in the code or @param in function declaration
- if you assigned the value of a variable with one of the previous things, it will work too :

```php
$x = $this->getRequest();
$x->{autocompletion}
```

### So, what will not work ?

For the moment, everything else does not work e.g :
```php
$x = new DateTime();
$x->{fail}

$x = self::getId();
$x->{fail}
```

The solution ? If you really need it, use the annotation **var**
```php
/** @var DateTime */
$x = new DateTime();
$x->{YEAAAAH}

/** @var MyIdClass */
$x = self::getId();
$x->{YEAAAAH}
```

Note : The multiline autocompletion **works**

# Next

Keep in mind that this plugin is under active development. If you find a bug, please, open an issue with the more possible informations on how to produce the bug.
Feel free to contribute ;)

![A screenshot of your spankin' package](https://f.cloud.github.com/assets/69169/2290250/c35d867a-a017-11e3-86be-cd7c5bf3ff9b.gif)
