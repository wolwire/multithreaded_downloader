import consumer from "./consumer"

consumer.subscriptions.create("NotesChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
    console.log("Connected to the chat room!");
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
    console.log("Connected to the chat room!");
  },

  received(data) {
    $('.messages').empty()
    $('.messages').append('<p class="received"> ' + data + '</p>')
  },

  speak(message) {
    this.perform('speak', { message: message })
  }
});
