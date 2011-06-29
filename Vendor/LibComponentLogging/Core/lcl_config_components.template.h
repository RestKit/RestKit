//
//
// lcl_config_components.h
//
//
// Copyright (c) 2008-2011 Arne Harren <ah@0xc0.de>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

//
// lcl_config_components.h template.
//


//
// The lcl_config_components.h file is used to define the application's log
// components.
//
// Use the code
//
//   _lcl_component(<identifier>, <header>, <name>)
//
// for defining a log component, where
//
// - <identifier> is the unique name of a log component which is used in calls
//   to lcl_log etc. A symbol 'lcl_c<identifier>' is automatically created for
//   each log component.
//
// - <header> is a C string in UTF-8 which should be used by a logging back-end
//   when writing a log message for the log component. The header is a technical
//   key for identifying a log component's messages. It is recommended to use
//   a 'Reverse ICANN' naming scheme when the header contains grouping
//   information, e.g. 'example.main.component1'.
//
// - <name> is a C string in UTF-8 which contains the name of the log component
//   and its grouping information in a non-technical, human-readable way
//   which could be used by a user interface. Groups should be separated by the
//   path separator '/', e.g. 'Example/Main/Component 1'.
// 


//
// Examples
//

_lcl_component(Main,            "main",             "Main")
_lcl_component(MainComponent1,  "main.component1",  "Main/Component1")
_lcl_component(MainComponent2,  "main.component2",  "Main/Component2")

_lcl_component(Main2,           "main2",            "Main2")

_lcl_component(Main3,           "main3",            "Main3")

