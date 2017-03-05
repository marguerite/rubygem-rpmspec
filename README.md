RPMSpec

=====

[![Code Climate](https://codeclimate.com/github/marguerite/rubygem-rpmspec/badges/gpa.svg)](https://codeclimate.com/github/marguerite/rubygem-rpmspec)

`RPMSpec` parses an RPM specfile into Ruby structs. It not only parses the `tag`s, but also macros, stages like `%install`, file lists, changelog and etc. It can also parse conditional requirements and scriptlets.

It is distributed as a standard rubygem and licensed under MIT.

#### Terms ####

* tag: 'Name', 'Version'...
* macro: `%define a %(/usr/bin/echo "a")`, `%{!?b %global b %(/usr/bin/echo "b")}`
* stage: `%prep`, `%build`...
* conditional requirements:

        %if 0%{?suse_version}
        BuildRequires:  a
        %else
        BuildRequires:  b
        %endif
        
#### Usage ####

        require 'rpmspec'
        specfile = RPMSpec::Parser.new('test.spec').parse

        # get package name
        puts specfile.name # => 'Test'
        
Some tags are always single for one package (sub package is a different package). eg:

`Name`, `Version`, `Release`, `License` or `BuildRoot`. Such tags' values are just plain text.
So they can always be fetched with `spec.#{tag}`.

Some other tags have multiple values (returned as Array of Structs) and own attributes. eg:

A changelog entry contains: modificatioin time, version, the packager's name, the packager's email,
and the detailed changes. So it is returned with another struct.

A summary of such structs:

| Tag        | Atrributes                                           |
|------------|------------------------------------------------------|
| changelog  | modification\_time, version, packager, email, changes |
| dependency | name, version, conditionals, modifier                |
| source     | number, url                                          |
| patch      | number, name, comment                                |
| macro      | indicator, name, expression, test                    |
| scriptlet  | name, content, conditionals                          |
| file       | file, permission, user, group, dirpermission, ghost  |

##### Dependencies #####

`dependency`: it can be 'BuildRequires', 'Requires', 'Provides'...see version.rb::DEPENDENCY\_TAGS.

`conditionals`: an array `["%if 0%{?suse_version} >= 1320", "%if 0%{?suse_version}"]`. Basically, if:

        %if 0%{?suse_version}
        BuildRequires:  a
        %if 0%{?suse_version} >= 1320
        BuildRequires:  b
        BuildRequires:  c
        %endif
        %else
        BuildRequires:  d
        %endif
        
Then, `specfile.buildrequires` will return an array contains a, b, c and d. But their conditionals are different, eg:

        c # => <#Struct 'name'='c' 'conditionals'=['%if 0%{?suse_version}', '%if 0%{?suse_version} >= 1320'] 'modifier'=nil>
        d # => <#Struct 'name'='d' 'conditionals'=['%if !0%{?suse_version}'] 'modifier'=nil>

`modifier`: eg `Requires(post)`, the modifier is `post`.

Because we need the parser to pick up dependencies tags with their conditionals first, dependencies can't 
be processed alone with its class 'RPMSpec::Dependency' without the parser.

The same strategy applies to `post|pre|*` Scriptlet, too.

##### Self-defined Macros #####

`indicator`: There're two ways to self-define a macro inside specfile: `%define` and `%global`.

`test`: return `true` if sometimes packagers check the existence of a macro like this `%{!?macro %define macro}`.

##### File Lists #####

The File list is a bit complicated. It is catalogued by categories first:

        specfile.files # => <#OpenStruct 'defattr'=>(skipped) 'doc'=>[], 'config'=>[], 'license'=>[], 'file'=>[], 'list'=>[]>

The categories refer to things like `%doc COPYING`, the plain uncatalogued files are under `file` category.

The `list` category refers to things like `%files lang -f test.lang`, the 'test.lang' is the appended file list.
        
So you need to navigate to the special category first:

        specfile.files.doc # => [<#Struct 'file'='COPYING' permission='-' user='root' group='root' dirpermission=nil ghost=false>]
        
The 'permission', 'user', 'group', 'dirpermission' comes from `specfile.files.defattr` by default, which is a struct:

        specfile.files.defattr # => <#Struct 'permission'='-', 'user'='root', group='root', dirpermission='-'>
        
It refers to the `%defattr(-,root,root,-)`. If there're things like `%attr(0755, test, test) %{_localstatedir}/log/test.org`,
the file permissions and ownerships will always be different.

`ghost` indicates if this file is a ghost file eg: `%ghost %{_sysconfdir}/test.conf`.

##### Sub Packages #####

        specfile.subpackages # => [<#OpenStruct similar with specfile itself>, <#OpenStruct ... >] 

Sub packages are actually normal packages without some build worker instruction tags like `BuildRoot`.

In order to separate the single tags, we split sub packages with our parser first.

So sub packages can't be processed without the parser either.

##### Stages #####

        specfile.install # => everything under %install section in plain text
        
Stages are almost the same, so they are processed by the parser in a way of creating dynamical classes.

They can't be processed without the parser either.

##### Advanced Usage #####

Here we can fetch things like changelogs, sources, patches, the preamble, macros,
and, if no subpackage, the description and the file list, easily with their classes

        # get the specfile's content
        f = open('test.spec').read
        # get sources for example
        sourceobj = RPMSpec::Source.new(f)
        oldsources = sourceobj.sources
        # Now replace the sources with yours
        newspecfile = f.sub(sourceobj.inspect(oldsources), <Your texts>)

If you just want the single tag like 'Name' or 'Version', you don't need this gem
actually, it's much more simple with these codes:

        f = open('test.spec').read
        m = f.match(/^Name:(.*?)\n/)
        name = m[1]
        newspecfile = f.sub(name, 'Your Name')
