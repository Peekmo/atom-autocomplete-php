# atom-autocomplete-php package

[![Join the chat at https://gitter.im/Peekmo/atom-autocomplete-php](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/Peekmo/atom-autocomplete-php?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Warning

The plugin seems to not work well with the last version (0.206.0) of atom.

Use *atom --include-deprecated-apis* to use it. I don't know why because I haven't got deprecations on the plugin. So, I need to learn more about changes.

# What is done ?

This plugin provide those amazing features :
- Autocompletion on class names with use auto added
- Autocompletion on class properties and methods. If your PHP doc is right, you should have autocompletion on X levels (e.g : $this->doctrine->getRepo...) (just works inline for now)
- Local function variables autocompletion
- Writing namespace in top of the file (ctrl - alt - n)
- Autocompletion on PHP internal functions

# How to make it works ?

First, you need the [autocomplete-plus](https://atom.io/packages/autocomplete-plus) package installed.

Secondly, only the PHP projects that use [composer](https://getcomposer.org/) to manage their autoload and dependencies are supported. In fact, to give you the autocompletion, the plugin use composer's classmap. So only a project with composer will have all the features. (Some are available without, but not the most interesting ;)

Finally, your project must follow the PSR norm, some weird things could happen otherwise.

# Settings

To configure the plugin, click on "package" in your preferences, and select "settings" on atom-autocomplete-php plugin.

![Configuration](http://i.imgur.com/MCtNGJQ.png)

## Options :
- *Command to use composer* : it's highly recommended to write here the full path to your composer.phar bin. E.G on unix systems, it could be /usr/local/bin/composer. Using an alias is not recommended at all !
- *Command php* : Command to execute PHP cli in your console. (php by default on unix systems). If it doesn't work, put here the full path to your PHP bin.
- *Composer autoload directories* : Write here, a coma separated list of all the different directories where your composer vendors are in your different projects. By default, it's "vendor", but if you changed it, make sure to update this list ;)

# Next

Keep in mind that this plugin is under active development. If you find a bug, please, open an issue with the more possible informations on how to produce the bug.
Feel free to contribute ;)

![A screenshot of your spankin' package](https://f.cloud.github.com/assets/69169/2290250/c35d867a-a017-11e3-86be-cd7c5bf3ff9b.gif)
