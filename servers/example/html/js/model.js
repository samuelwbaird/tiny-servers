// reference the hair library to hook into the signal/watch mechanism
import * as hair from '../../js/hair.js';
import * as api from '../../tiny-servers/api.js';

export default class EmojiAppModel {
	
	constructor (name) {
		this.connected = false;
		this.emojiLog = null;
		// read the log on launch
		
		this.readEmojiLog();
		
		// refresh data on a timer, or if not yet connected
	}
	
	async readEmojiLog() {
		const result = await api.call('example', 'emojis', {});
		if (result.success) {
			this.connected = true;
			this.emojiLog = result.data;
			// signal the model is updated
			hair.signal(this);
		}
	}
	
	async deleteEmoji(entry) {
		const index = this.emojiLog.indexOf(entry);
		if (index > -1) {
			this.emojiLog.splice(index, 1);
			hair.signal(this);
		}
		return new api.ApiResult(false, null, 'You must be an admin');
	}
	
	async addEmoji(emoji) {
		this.emojiLog.unshift({
			id: 1,
			emoji: emoji,
			identity: 'who knows',
			time: (Date.now() / 1000)
		});
		hair.signal(this);
		return new api.ApiResult(true, null, null);
	}
	
}