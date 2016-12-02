'use babel';

import ProtoReplSayid from '../lib/proto-repl-sayid';

// Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
//
// To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
// or `fdescribe`). Remove the `f` to unfocus the block.

describe('ProtoReplSayid', () => {
  let workspaceElement, activationPromise;

  beforeEach(() => {
    workspaceElement = atom.views.getView(atom.workspace);
    activationPromise = atom.packages.activatePackage('proto-repl-sayid');
  });

  describe('when the proto-repl-sayid:toggle event is triggered', () => {
    it('hides and shows the modal panel', () => {
      // Before the activation event the view is not on the DOM, and no panel
      // has been created
      expect(workspaceElement.querySelector('.proto-repl-sayid')).not.toExist();

      // This is an activation event, triggering it will cause the package to be
      // activated.
      atom.commands.dispatch(workspaceElement, 'proto-repl-sayid:toggle');

      waitsForPromise(() => {
        return activationPromise;
      });

      runs(() => {
        expect(workspaceElement.querySelector('.proto-repl-sayid')).toExist();

        let protoReplSayidElement = workspaceElement.querySelector('.proto-repl-sayid');
        expect(protoReplSayidElement).toExist();

        let protoReplSayidPanel = atom.workspace.panelForItem(protoReplSayidElement);
        expect(protoReplSayidPanel.isVisible()).toBe(true);
        atom.commands.dispatch(workspaceElement, 'proto-repl-sayid:toggle');
        expect(protoReplSayidPanel.isVisible()).toBe(false);
      });
    });

    it('hides and shows the view', () => {
      // This test shows you an integration test testing at the view level.

      // Attaching the workspaceElement to the DOM is required to allow the
      // `toBeVisible()` matchers to work. Anything testing visibility or focus
      // requires that the workspaceElement is on the DOM. Tests that attach the
      // workspaceElement to the DOM are generally slower than those off DOM.
      jasmine.attachToDOM(workspaceElement);

      expect(workspaceElement.querySelector('.proto-repl-sayid')).not.toExist();

      // This is an activation event, triggering it causes the package to be
      // activated.
      atom.commands.dispatch(workspaceElement, 'proto-repl-sayid:toggle');

      waitsForPromise(() => {
        return activationPromise;
      });

      runs(() => {
        // Now we can test for view visibility
        let protoReplSayidElement = workspaceElement.querySelector('.proto-repl-sayid');
        expect(protoReplSayidElement).toBeVisible();
        atom.commands.dispatch(workspaceElement, 'proto-repl-sayid:toggle');
        expect(protoReplSayidElement).not.toBeVisible();
      });
    });
  });
});
