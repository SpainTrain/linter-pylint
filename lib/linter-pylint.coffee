{exec} = require 'child_process'
linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"

class LinterPylint extends Linter
  @syntax: 'source.python' # fits all *.py-files

  linterName: 'pylint'

  regex: '^(?<line>\\d+),(?<col>\\d+),\
          ((?<error>fatal|error)|(?<warning>warning|convention|refactor)),\
          (?<msg_id>\\w\\d+):(?<message>.*)$'
  regexFlags: 'm'

  constructor: (@editor) ->
    super @editor

    # sets @cwd to the dirname of the current file
    # if we're in a project, use that path instead
    # TODO: Fix this up so it works with multiple directories
    paths = atom.project.getPaths()
    @cwd = paths[0] || @cwd

    # Set to observe config options
    @executableListener = atom.config.observe 'linter-pylint.executable', => @updateCommand()
    @rcFileListener = atom.config.observe 'linter-pylint.rcFile', => @updateCommand()
    @messageFormatListener = atom.config.observe 'linter-pylint.messageFormat', => @updateCommand()

  destroy: ->
    super
    @executableListener.dispose()
    @rcFileListener.dispose()
    @messageFormat.dispose()

  # Sets the command based on config options
  updateCommand: ->
    format = atom.config.get 'linter-pylint.messageFormat'
    for pattern, value of {'%m': 'msg', '%i': 'msg_id', '%s': 'symbol'}
        format = format.replace(new RegExp(pattern, 'g'), "{#{value}}")
    cmd = [atom.config.get 'linter-pylint.executable']
    cmd.push "--msg-template='{line},{column},{category},{msg_id}:#{format}'"
    cmd.push '--reports=n'
    cmd.push '--output-format=text'

    rcFile = atom.config.get 'linter-pylint.rcFile'
    if rcFile
      cmd.push "--rcfile=#{rcFile}"

    @cmd = cmd


module.exports = LinterPylint
