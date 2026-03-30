// reference the hair library to hook into the signal/watch mechanism
import * as hair from '../../js/hair.js';
import * as api from '../../tiny-servers/api.js';

export default class EmojiAppModel {
	
	constructor (name) {
		this.connected = false;
		this.emojiLog = null;
		
		// read the log on launch
		this.readEmojiLog();
		
		// refresh data on a timer, or if not yet connected?
		
		// make the tiny servers login button available
		api.enableSignIn();
	}
	
	async readEmojiLog() {
		const result = await api.call('example', 'emojis', {});
		if (result.success) {
			this.connected = true;
			this.emojiLog = result.data;
			hair.signal(this);
		}
	}
	
	async addEmoji(emoji) {
		const result = await api.call('example', 'add_emoji', { emoji: emoji });
		if (result.success) {
			this.emojiLog.unshift(result.data);
			hair.signal(this);
		}
		return result;
	}
	
	async deleteEmoji(entry) {
		const result = await api.call('example', 'delete_emoji', { id: entry.id });
		if (result.success) {
			const index = this.emojiLog.indexOf(entry);
			if (index > -1) {
				this.emojiLog.splice(index, 1);
				hair.signal(this);
			}
		}
		return result;
	}
}