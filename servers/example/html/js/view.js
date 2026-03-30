// reference the hair library to access the provided functions to generate elements
import * as h from '../../js/hair.js';

/** top level view, render the app as a title, list, and "add new" component */
export default function app (model) {
	return [
		h.h1('Emoji Log'),
		h.h2('An example tiny server'),
		
		(model.connected ? [
			// view if connected
			emojiLogView(model),
			addEmojiView(model),
		] : [
			// view if still loading
			h.p('loading...'),
		]),
	];
}

function emojiLogView(model) {
	// render a grid view of every emoji in the log
	return h.div({ class: 'emoji-log-container' }, [
		h.compose(model.emojiLog, (entry) => {
			return [
				h.div(entry.emoji),
				h.div(entry.identity),
				h.div(formatTimestamp(entry.timestamp)),
				h.button('❌', {}, h.listen('click', async () => {
					if (window.confirm('Are you sure you wish to delete this emoji?')) {
						const result = await model.deleteEmoji(entry);
						if (!result.success) {
							alert(result.error);
						}
					}
				})),
			];
		}),
	]);
}

function formatTimestamp(time) {
	const date = new Date(time * 1000);
	const formatted = (
		date.getFullYear() + '/' + 
		String(date.getMonth()).padStart(2, '0') + '/' + 
		String(date.getDate()).padStart(2, '0') + ' ' + 
		String(date.getHours()).padStart(2, '0') + ':' + 
		String(date.getMinutes()).padStart(2, '0') + ':' + 
		String(date.getSeconds()).padStart(2, '0')
	);	
	return formatted;
}

function addEmojiView(model) {
	// render the button to log an emoji
	const available_emojis = [
		'👍🏻', '😬', '😅', '😩', '🍃'
	];
	return h.div({ class: 'emoji-panel' }, [
		h.span('Add an emoji to the log'),
		h.compose(available_emojis, (emoji) => {
			return h.button(emoji, { class: 'emoji-button' }, h.listen('click', async () => {
				const result = await model.addEmoji(emoji);
				if (!result.success) {
					alert(result.error);
				}
			}));
		}),
	]);
}
