BackgroundTipsView = require '../lib/background-tips-view'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "BackgroundTips", ->
  [workspaceElement, backgroundTips, backgroundTipsView] = []

  BackgroundTipsView::DisplayDuration = 5
  BackgroundTipsView::FadeDuration = 1

  activatePackage = (callback) ->
    waitsForPromise ->
      atom.packages.activatePackage('background-tips').then ({mainModule}) ->
        {backgroundTipsView} = mainModule

    runs ->
      callback()

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

  describe "when the package is activated when there is only one pane", ->
    beforeEach ->
      expect(atom.workspace.getPanes().length).toBe 1

    describe "when the pane is empty", ->
      it "attaches the view after a delay", ->
        expect(atom.workspace.getActivePane().getItems().length).toBe 0

        activatePackage ->
          expect(backgroundTipsView.parentNode).toBeFalsy()
          advanceClock BackgroundTipsView::StartDelay + 1
          expect(backgroundTipsView.parentNode).toBeTruthy()

    describe "when the pane is not empty", ->
      it "does not attach the view", ->
        waitsForPromise -> atom.workspace.open()

        activatePackage ->
          advanceClock BackgroundTipsView::StartDelay + 1
          expect(backgroundTipsView.parentNode).toBeFalsy()

    describe "when a second pane is created", ->
      it "detaches the view", ->
        activatePackage ->
          advanceClock BackgroundTipsView::StartDelay + 1
          expect(backgroundTipsView.parentNode).toBeTruthy()

          atom.workspace.getActivePane().splitRight()
          expect(backgroundTipsView.parentNode).toBeFalsy()

  describe "when the package is activated when there are multiple panes", ->
    beforeEach ->
      atom.workspace.getActivePane().splitRight()
      expect(atom.workspace.getPanes().length).toBe 2

    it "does not attach the view", ->
      activatePackage ->
        advanceClock BackgroundTipsView::StartDelay + 1
        expect(backgroundTipsView.parentNode).toBeFalsy()

    describe "when all but the last pane is destroyed", ->
      it "attaches the view", ->
        activatePackage ->
          atom.workspace.getActivePane().destroy()
          advanceClock BackgroundTipsView::StartDelay + 1
          expect(backgroundTipsView.parentNode).toBeTruthy()

          atom.workspace.getActivePane().splitRight()
          expect(backgroundTipsView.parentNode).toBeFalsy()

          atom.workspace.getActivePane().destroy()
          expect(backgroundTipsView.parentNode).toBeTruthy()

  describe "when the view is attached", ->
    beforeEach ->
      expect(atom.workspace.getPanes().length).toBe 1

      activatePackage ->
        advanceClock BackgroundTipsView::StartDelay
        advanceClock BackgroundTipsView::FadeDuration

    it "has text in the message", ->
      expect(backgroundTipsView.parentNode).toBeTruthy()
      expect(backgroundTipsView.message.textContent).toBeTruthy()

    it "changes text in the message", ->
      oldText = backgroundTipsView.message.textContent
      waits BackgroundTipsView::DisplayDuration + BackgroundTipsView::FadeDuration
      runs ->
        advanceClock BackgroundTipsView::FadeDuration
        expect(backgroundTipsView.message.textContent).not.toEqual(oldText)
