'use strict'

import * as prettier from 'npm:prettier'
import * as path from 'node:path'

const SCRIPT_PATH = path.join(Deno.cwd(), 'script.js')
const STYLES_PATH = path.join(Deno.cwd(), 'styles.css')

Deno.serve(async (req: Request) => {
    const path = new URL(req.url).pathname
    switch(path) {
        case '/script.js':
            return serveStaticFile(SCRIPT_PATH, 'application/javascript')
        case '/styles.css':
            return serveStaticFile(STYLES_PATH, 'text/css')
        case '/formatted.json': {
            const formattedMap: Record<string, string> = {}
            for (const testCase of findTestCases()) {
                formattedMap[testCase.name] = await prettier.format(testCase.js, { parser: 'babel' })
            }
            return new Response(JSON.stringify(formattedMap), { headers: { 'content-type': 'application/json' } })
        }
        case '/': {
            const html = generateHtml({ testCases: findTestCases() })
            return new Response(html, { headers: { 'content-type': 'text/html' } })
        }
        default:
            return new Response('404 - Not Found', { status: 404 })
    }
})

function serveStaticFile(path: string, contentType: string): Response {
    try {
        const file = Deno.readFileSync(path)
        return new Response(file, { headers: { 'content-type': contentType } })
    } catch (err) {
        if (err instanceof Deno.errors.NotFound) {
            return new Response('404 - Not Found', { status: 404 })
        }
        throw err
    }
}

interface TestCase {
    name: string
    rb: string
    js: string
}

function findTestCases(): TestCase[] {
    const testCases: TestCase[] = []
    const rbDir = '../testdata/rb'
    const jsDir = '../testdata/js'

    const rbFiles = Deno.readDirSync('../testdata/rb')
    for (const rbFile of rbFiles) {
        const basename = path.basename(rbFile.name, '.rb')

        const rbPath = path.join(rbDir, rbFile.name)
        const rb = Deno.readTextFileSync(rbPath)

        const tryReadFileIfExists = (path: string) => {
            try {
                return Deno.readTextFileSync(path)
            } catch (err) {
                if (err instanceof Deno.errors.NotFound) {
                    return ''
                }
                throw err
            }
        }

        const jsPath = path.join(jsDir, `${basename}.js`)
        const js = tryReadFileIfExists(jsPath)

        testCases.push({ name: basename, rb, js })
    }

    return testCases
}

interface GenerateHtmlParams {
    testCases: TestCase[]
}

function generateHtml({ testCases }: GenerateHtmlParams): string {
  return `
    <!DOCTYPE html>
    <html lang='en'>
    <head>
      <title>Test Cases</title>

      <link rel='stylesheet' href='/styles.css'>
      <script type='module' src='./script.js' defer></script>

      <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/highlight.js@11.8.0/styles/github-dark.css">
    </head>
    <body>
      <table>
        <thead>
          <tr>
            <th>Ruby</th>
            <th>JavaScript</th>
          </tr>
        </thead>
        <tbody>
          ${testCases.sort((a, b) => a.name.localeCompare(b.name)).map((tc) => `
              <tr>
                <td><pre><code id='rb-${tc.name}' class='language-ruby' title='${escapeHtml(tc.name)}'>${escapeHtml(tc.rb)}</code></pre></td>
                <td><pre><code id='js-${tc.name}' class='language-javascript' title='${escapeHtml(tc.name)}'>${escapeHtml(tc.js)}</code></pre></td>
              </tr>
            `).join('')}
        </tbody>
      </table>
    </body>
    </html>
  `
}

function escapeHtml(unsafe: string): string {
    return (
        unsafe
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;")
    )
}