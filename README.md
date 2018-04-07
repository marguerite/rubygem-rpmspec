RPMSpec

------

[![Code Climate](https://codeclimate.com/github/marguerite/rubygem-rpmspec/badges/gpa.svg)](https://codeclimate.com/github/marguerite/rubygem-rpmspec)

`RPMSpec` parses an RPM specfile into Ruby OpenStructs. It not only parses the `tag`s, but also macros, stages like `%install`, file lists, changelog and etc. It can also parse conditional requirements and scriptlets.

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
        puts specfile.name # => ['Test']

##### Dependencies #####

`dependency`: it can be 'BuildRequires', 'Requires', 'Provides'...

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

        c # => <#OpenStruct 'name'='c' 'conditionals'=['%if 0%{?suse_version}', '%if 0%{?suse_version} >= 1320'] 'modifier'=nil>
        d # => <#OpenStruct 'name'='d' 'conditionals'=['%if !0%{?suse_version}'] 'modifier'=nil>

`modifier`: eg `Requires(post)`, the modifier is `post`.

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

##### Stages #####

        specfile.install # => everything under %install section in plain text
