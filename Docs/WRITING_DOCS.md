Writing Documentation
=====================

RestKit utilizes the excellent [Appledoc](http://www.gentlebytes.com/home/appledocapp/) utility from [Gentle Bytes](http://www.gentlebytes.com/). 
Appledoc provides a commandline utility for parsing and generating documentation from Objective-C code in HTML and DocSet format. This HTML can be
published to the Web and installed directly within Xcode. 

To generate meaningful and informative documentation, Appledoc needs support in the form of markup within the header files. This document
seeks to outline the process for marking up RestKit headers to generate great end-user documentation directly from the source code.

## Generating Documentation

RestKit ships with a set of Rake tasks that simplify the task of generating documentation. A compiled x86_64 executable of the Appledoc
utility is provided with the RestKit distribution at the Vendor/appledoc path. Most authors will not need to interact directly with
Appledoc since the process has been automated.

The tasks available for working with Appledoc are:

1. `rake docs:generate` - Generates a set of HTML documentation in Docs/API/html
1. `rake docs:check` - Runs the RestKit sources through the parser to detect any issues preventing documentation generation
1. `rake docs:install` - Generates and installs an Xcode DocSet viewable through the Xcode organizer and integrated help viewer

## Writing Documentation

Writing documentation in Appledoc markup is simple. There is extensive documentation available on the [Appledoc project page](http://tomaz.github.com/appledoc/comments.html), but 
the guidelines below should be sufficient for basic authoring tasks. For clarity, let's consider the following example class:    
    
    /**
     * Demonstrates how to document a RestKit class using Appledoc
     *
     * This class provides a simple boilerplate example for how to properly document
     * RestKit classes using the Appledoc system. This paragraph forms the details
     * description of the class and will be presented in detail
    @interface RKDocumentationExample : NSObject {
        NSString* _name;
        NSString* _rank;
        NSString* _serialNumber;
    }
    
    /// @name Demonstrates Documentation Task Groups
    
    /**
     * Returns the name of the person in this documentation example
     *
     * This property is *important* and that's why the preceeding text will be bolded
     */
     @property (nonatomic, retain) NSString* name;
     
     /**
      * The rank of this example in the theoretical documentation hierarchy
      *
      * This one is _somewhat important_, so we emphasized that text
      *
      * Can be one of the following unordered lists:
      * - Captain
      * - General
      * - Private
      */
     @property (nonatomic, retain) NSString* rank;
     
     /**
      * Serial number for this example, as issued by the Colonial Fleet of the 12 Colonies of Kobol
      *
      * @warning Somebody might be a Cylon
      @ @see RKDocumentationSerialNumberGenerator
      */
     @property (nonatomic, retain) NSString* serialNumber;
     
     /**
      * Promotes the example to the rank specified
      *
      * For example: `[exampleObject promoteToRank:@"General"];`
      * 
      * @bug This might be broken
      * @param rank The rank to promote the example to
      */
     - (void)promoteToRank:(NSString*)rank;
     
     /**
      * Returns the next rank for this example.
      * 
      * @return The next rank this example could be promoted to
      * @exception RKInvalidRankException Raised when there is no current rank
      */
     - (NSString*)nextRank;
     
     @end
     
1. Documentation blocks must precede the item being documented and begin with a slash and a double star. They must be terminated with a single star and a slash.
1. The first paragraph forms the short description of the entity being documented.
1. The second paragraph forms the long description of the entity and can contain an arbitrary number of paragraphs.
1. Methods & properties can be grouped together by using the @name directive. The directive must follow 3 delimiting characters. RestKit standard is '///'
1. Text can be bolded and italicized using Markdown standard (i.e. *bolded* and _italicized_)
1. Markdown text such as unordered and ordered lists and links can be embedded into the descriptions as appropriate.
1. @warning and @bug can be used to call out specific warnings and known issues in the codebase
1. Code spans can be embedded by using backticks
1. Method arguments should be documented clearly using "@param <param name> Brief description here"
1. Method return values should be documented using "@return A description of the return value"
1. Exceptions should be documented using "@exception <exception type> Description of the exception raised"
1. Cross references to other parts of the codebase can be generated via "@see SomeOtherClass" or "@see [SomeClass someMethod:withArguments:]"

## Submitting Documentation

If you want to contribute documentation, the process is simple:

1. Fork the codebase from the current development branch
1. Generate a set of docs to work with via `rake docs` and open `Docs/API/html/index.html` in your browser
1. Edit the headers in Code/ and regenerate the docs via `rake docs`
1. Repeat the editing and reload cycle until your are happy.
1. Commit the code and push to Github
1. Submit a Pull Request to the RestKit repository on Github at: https://github.com/RestKit/RestKit/pull/new/master

You may want to coordinate your efforts via the mailing list to ensure nobody else is working on documentation in the same place.
