'use babel';

import ProtoReplSayidView from './proto-repl-sayid-view';
import { CompositeDisposable } from 'atom';

export default {

  protoReplSayidView: null,
  modalPanel: null,
  subscriptions: null,

  activate(state) {
    this.protoReplSayidView = new ProtoReplSayidView(state.protoReplSayidViewState);
    this.modalPanel = atom.workspace.addModalPanel({
      item: this.protoReplSayidView.getElement(),
      visible: false
    });

    // Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable();

    // Register command that toggles this view
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'proto-repl-sayid:toggle': () => this.toggle()
    }));
  },

  deactivate() {
    this.modalPanel.destroy();
    this.subscriptions.dispose();
    this.protoReplSayidView.destroy();
  },

  serialize() {
    return {
      protoReplSayidViewState: this.protoReplSayidView.serialize()
    };
  },

  toggle() {
    console.log('ProtoReplSayid was toggled!');
    return (
      this.modalPanel.isVisible() ?
      this.modalPanel.hide() :
      this.modalPanel.show()
    );
  }

};
