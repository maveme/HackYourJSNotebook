module javascript::JSRepl

import String;
import ParseTree;
import bacata::salix::Bridge;
import bacata::Notebook;
import bacata::util::Util;
import bacata::util::Proposer;
import javascript::Plugin;
import javascript::Syntax;
import demo::HAML;
import salix::HTML;
import demo::SelectQuery;
import demo::StateMachine;


public REPL jsREPL(){
	return repl( handl, complet);
} 

CommandResult handl(str line){
	errors=[];
	rst = "";
	try{
		pt = parse(#start[Source], line);
		<js, xref, renaming> = desugarAndResolve(pt);
        fixed = rename(js, renaming);
        original = translate(pt);

        desugared = translate(fixed);
        desugaredSrc = unparse(fixed);

        rst = toHTML(jsView);
        
        str merge(str template) {
			template = replaceAll(template, "{{original}}", original);
			template = replaceAll(template, "{{desugared}}", desugared);
			template = replaceAll(template, "{{desugaredSrc}}", desugaredSrc);
			return template;
		}
        
        rst += merge(jsTemplate());
        return textual("<rst>", messages = errors);
	}
	catch ParseError(lo):
	{
		errors = [error("Parse error at <lo>")];
		return textual(rst, messages = errors);
	}
}

Completion complet(str prefix, int offset) {
	proposerFunction = proposer(#Source);
   	return < 0, ["<prop.newText>" | prop <- proposerFunction(prefix, offset)] >;
}

str translate(start[Source] orig) {
 	str toJsStr(str code) {
		code = replaceAll(code, "\n", " \\n \\\n");
		code = replaceAll(code, "\"", "\\\"");
		code = replaceAll(code, "\'", "\\\'");
		return code;
	}
 	return toJsStr(unparse(orig));
}

void jsView(){
	div(class("row"), () {
		div(class("col-md-6"), () {
    		h4("Original SweeterJS source");
    			div(class("code"), id("original"), () {
    		});
    	});
    	div(class("col-md-6"), () {
    		h4("Desugared JS source");
    			div(class("code"), id("transformed"), () {
    		});
    	});
    	div(class("row"), () {
    		div(class("col-md-12"), () {
	    		h4("Console output of running the desugared version");
	    			div(id("log"), () {
	    		});
	    	});	
    	});	
    });
}


str jsTemplate() =
"\<script\>
'		CodeMirror(document.getElementById(\"original\"), {
'			value: 
'\" \\
'{{original}} \\
'\",
'			mode: \"javascript\",
'			lineNumbers: true,
'			readOnly: true,
'			}); 
'
'		CodeMirror(document.getElementById(\"transformed\"), {
'			value: 
'\" \\
'{{desugared}} \\
'\",
'			mode: \"javascript\",
'			lineNumbers: true,
'			readOnly: true,
'			}); 
'
'\</script\>
'
'\<script\>
'var DEBUG_FLAG = true;
'var logger = document.getElementById(\'log\');
'var createElem = function(elemType, className, innerText) {
'	var elem = document.createElement(elemType);
'	if (className !== undefined) {
'		elem.className = className;
'	}
'
'	if (innerText !== undefined) {
'		elem.textContent = innerText;
'		elem.innerText = innerText;
'	}
'	return elem;
' }
'
'console.log = function (message) {
'    if (typeof message == \'object\') {
'        logger.appendChild(createElem(\"p\", \"info\", JSON && JSON.stringify ? JSON.stringify(message) : message));
'    } else {
'        logger.appendChild(createElem(\"p\", \"info\", message));
'    }       
'}
'
'console.error = function (message) {
'    if (typeof message == \'object\') {
'        logger.appendChild(createElem(\"p\", \"error\", JSON && JSON.stringify ? JSON.stringify(message) : message));
'      	} else {
'        logger.appendChild(createElem(\"p\", \"error\", message));
'    }       
'}    
'
'\</script\>
'
'\<script\>
'	try {
'		{{desugaredSrc}}
'	} catch (e) {
'		if (e instanceof Error) {
'			console.error(e.message);
'		} else {
'			console.error(e);
'		}
'	}
'\</script\>";