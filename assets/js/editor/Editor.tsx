import React, { useState, useCallback, useEffect, useRef } from 'react';
import Monaco from "@monaco-editor/react";
import type { EditorProps as MonacoProps } from  "@monaco-editor/react/lib/types";

import { fetchDTSListing, fetchFile } from '@openfn/describe-package';

const DEFAULT_TEXT = '// Get started by adding operations from the API reference';

type EditorProps = {
  source?: string;
  adaptor?: string; // fully specified adaptor name - <id>@<version>
  onChange?: (newSource: string) => void;
}

// https://microsoft.github.io/monaco-editor/api/interfaces/monaco.editor.IStandaloneEditorConstructionOptions.html
const defaultOptions: MonacoProps['options'] = {
  dragAndDrop: false,
  lineNumbersMinChars: 3,
  minimap: {
    enabled: false
  },
  scrollBeyondLastLine: false,
  showFoldingControls: 'always',
  
  // Hide the right-hand "overview" ruler
  overviewRulerLanes: 0,
  overviewRulerBorder: false,

  codeLens: false,
  wordBasedSuggestions: false,

  suggest: {
    showKeywords: false,
  }
};

type Lib = {
  content: string;
  filePath: string;
}

// TODO this can take a little while to run, we should consider giving some feedback to the user
async function loadDTS(specifier: string, type: 'namespace' | 'module' = 'namespace'): Promise<Lib[]> {
  // Work out the module name from the specifier
  // (his gets a bit tricky with @openfn/ module names)
  const nameParts = specifier.split('@')
  nameParts.pop() // remove the version
  const name = nameParts.join('@');
  
  let results: Lib[] = [];
  if (name && name !== '@openfn/language-common') {
    const pkg = await fetchFile(`${specifier}/package.json`)
    const commonVersion = JSON.parse(pkg || '{}').dependencies?.['@openfn/language-common'];
    results = await loadDTS(`@openfn/language-common@${commonVersion}`, 'module')
  }
  // if (name && name !== '@openfn/language-common') {
  //   // // so this works (without a filename!)
  //   // results.push({
  //   //   content: `declare module "@openfn/language-common" {
  //   //     /** hello */
  //   //     export function fn(x: number): number ;
  //   //   }`
  //   // })

  //   const pkg = await fetchFile(`${specifier}/package.json`)
  //   const commonVersion = JSON.parse(pkg || '{}').dependencies?.['@openfn/language-common'];
  //   if (commonVersion) {
  //     // const common = await loadDTS(`@openfn/language-common@${commonVersion}`)
  //     // results.push(...common)
  //     for await (const filePath of fetchDTSListing(`@openfn/language-common@${commonVersion}`)) {
  //       if (!filePath.startsWith('node_modules') && !filePath.endsWith('beta.d.ts')) {
  //       // if (filePath.endsWith('Adaptor.d.ts')) {
  //         const content = await fetchFile(`@openfn/language-common@${commonVersion}${filePath}`)
  //         results.push({
  //           content: `declare namespace "@openfn/language-common" { ${content} }`,
  //           // filePath
  //         });
  //       }
  //     }
  //   }
  // }

  for await (const filePath of fetchDTSListing(specifier)) {
    if (!filePath.startsWith('node_modules')) {
      const content = await fetchFile(`${specifier}${filePath}`)
      results.push({
        content: `declare ${type} "${name}" { ${content} }`,
        filePath: `${name}${filePath}`
      });
    }
  }
  console.log(results)
  return results;
}

export default function Editor({ source, adaptor, onChange }: EditorProps) {
  const [lib, setLib] = useState<Lib[]>();
  const [monaco, setMonaco] = useState<typeof Monaco>();
  const [options, setOptions] = useState(defaultOptions);
  const listeners = useRef<{ insertSnippet?: EventListenerOrEventListenerObject}>({});

  const handleSourceChange = useCallback((newSource: string) => {
    if (onChange) {
      onChange(newSource)
    }
  }, [onChange]);
  
  const handleEditorDidMount = useCallback((editor: any, monaco: typeof Monaco) => {
    setMonaco(monaco);

    monaco.languages.typescript.javascriptDefaults.setCompilerOptions({
      // This seems to be needed to track the modules in d.ts files
      allowNonTsExtensions: true,

      // Disables core js libs in code completion
      noLib: true,
    });

    listeners.current.insertSnippet = (e: Event) => {
      // Snippets are always added to the end of the job code
      const model = editor.getModel()
      const lastLine = model.getLineCount();
      const eol = model.getLineLength(lastLine)
      const op = {
        range: new monaco.Range(lastLine, eol, lastLine, eol),
        // @ts-ignore event typings
        text: `\n${e.snippet}`,
        forceMoveMarkers: true
      };
      
      // Append the snippet
      // https://microsoft.github.io/monaco-editor/api/interfaces/monaco.editor.ICodeEditor.html#executeEdits
      editor.executeEdits("snippets", [op]);

      // Ensure the snippet is fully visible
      const newLastLine = model.getLineCount();
      editor.revealLines(lastLine + 1, newLastLine, 0) // 0 = smooth scroll

      // Set the selection to the start of the snippet
      editor.setSelection(new monaco.Range(lastLine+1, 0, lastLine+1, 0));
      
      // ensure the editor has focus
      editor.focus();
    };

    document.addEventListener('insert-snippet', listeners.current.insertSnippet);
  }, []);

  useEffect(() => {
    // Create a node to hold overflow widgets
    // This needs to be at the top level so that tooltips clip over Lightning UIs
    const overflowNode = document.createElement('div');
    overflowNode.className = "monaco-editor widgets-overflow-container";
    document.body.appendChild(overflowNode);

    setOptions({
      ...defaultOptions,
      overflowWidgetsDomNode: overflowNode,
      fixedOverflowWidgets: true
    })

    return () => {
      overflowNode.parentNode?.removeChild(overflowNode);
      if (listeners.current?.insertSnippet) {
        document.removeEventListener('insert-snippet', listeners.current.insertSnippet);
      }
     }
  }, []);
  
  useEffect(() => {
    if (adaptor) {
      setLib([]); // instantly clear intelligence
      loadDTS(adaptor).then(l => setLib(l));
    }
  }, [adaptor])

  useEffect(() => {
    if (monaco) {
      monaco.languages.typescript.javascriptDefaults.setExtraLibs(lib);
    }
  }, [monaco, lib]);
  
  return (<Monaco
    defaultLanguage="javascript"
    loading=""
    theme="vs-dark"
    value={source || DEFAULT_TEXT}
    options={options}
    onMount={handleEditorDidMount}
    onChange={handleSourceChange}
  />)
}
