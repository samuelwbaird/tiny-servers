import * as h from '../js/hair-mini.js';

export const IDENTITY_UNKNOWN = 0;
export const IDENTITY_NOT_SIGNED_IN = 1;
export const IDENTITY_SIGNING_IN = 2;
export const IDENTITY_SIGNED_IN = 3;

let signInModel = {
	status: IDENTITY_UNKNOWN,
	identity: null,
	
	setIdentity: async (email) => {
		const result = await call('session', 'set_identity', { identity: email });
		if (result.success && result.data.identity) {
			signInModel.status = IDENTITY_SIGNED_IN;
			signInModel.identity = result.data.identity;
		} else {
			signInModel.status = IDENTITY_NOT_SIGNED_IN;
			signInModel.identity = null;
			alert(result.error);
		}
		h.signal(signInModel);
	},
	
	signOut: async () => {
		const result = await call('session', 'sign_out', {});
		signInModel.status = IDENTITY_NOT_SIGNED_IN;
		h.signal(signInModel);
	}
}

export function identityStatus() {
	return signInModel.status;
}

export async function call(server, api_name, parameters) {
	return await _http_api_request('../' + server + '/api/' + api_name, parameters);
}

export class ApiResult {
	constructor (success, data, error) {
		this.success = success;
		this.data = data;
		this.error = error;
	}
}

export async function enableSignIn() {
	// first check if we have a current session and if its valid
	if (signInModel.status == IDENTITY_UNKNOWN) {
		const result = await call('session', 'check_session', {});
		if (result.success && result.data.identity) {
			signInModel.status = IDENTITY_SIGNED_IN;
			signInModel.identity = result.data.identity;
		} else {
			signInModel.status = IDENTITY_NOT_SIGNED_IN;
			signInModel.identity = null;
		}
	}
	h.render(document.body, signInModel, signInView);
}

const styles = {
	wrapper: { position: 'absolute', zIndex: '1000', left: '0px', top: '0px', width: '100%', height: '0px', fontFamily: 'Tahoma, sans-serif', color: '#eee', },
	dialog: { marginLeft: 'auto', marginRight: '20px', marginTop: '0px', borderRadius: '0px 0px 10px 10px', padding: '5px', textAlign: 'center', backgroundColor: 'rgba(80, 80, 80, 1)', width: '250px', maxWidth: '90%', maxHeight: '50vh', boxSizing: 'border-box', fontSize: '13px'},
	small_text: { marginTop: '3px', marginBottom: '3px', fontSize: '13' },
}

function signInView () {
	return h.div({ style: styles.wrapper }, [
		h.div({ style: styles.dialog }, [
			signInPrompt,
			emailSubmitView,
			signedInView,
		]),
	]);
}

function signInPrompt (model) {
	if (model.status == IDENTITY_NOT_SIGNED_IN) {
		return h.p('Click here to sign in', { style: { cursor: 'pointer' }}, h.listen('click', (context, element) => {
			model.status = IDENTITY_SIGNING_IN;
			h.signal(model);
		}))
	}
}

function emailSubmitView (model) {
	if (model.status == IDENTITY_SIGNING_IN) {
		return [
			h.p('Sign in with email', { style: styles.small_text }),
			h.input({ context_id: 'txt_email', type: 'email', name: 'email', size: 22, value: model.identity ?? '', disabled: (model.status != IDENTITY_SIGNING_IN) }, [
				h.listen('keyup', (context, element, e) => {
					if (e.key == 'Enter') {
						model.setIdentity(context.txt_email.value);
					}
				}),
				h.onAttach((context, element) => {
					element.select();
					element.focus();
				})
			]),
			h.div({ style: { display: 'inline', marginRight: '10px' }}),
			h.button('Enter', { disabled: (model.status != IDENTITY_SIGNING_IN) }, h.listen('click', (context, element) => {
				model.setIdentity(context.txt_email.value);
			})),
			h.div({ style: { height: '10px' }}),
		];
	}
}

function signedInView (model) {
	if (model.status == IDENTITY_SIGNED_IN) {
		return h.p(model.identity, { style: { cursor: 'pointer' }}, h.listen('click', (context, element) => {
			model.signOut();
		}))
	}
}

async function _http_api_request(url, data) {
	const options = {
		method: 'POST',
		mode: 'cors',
		headers: {
			'Content-Type': 'application/json;charset=UTF-8'
		},
		body: JSON.stringify(data),
	};
	try {
		const response = await fetch(url, options);
		const json = await response.json();
		if (json.success) {
			return new ApiResult(true, json.data, null);
		} else {
			return new ApiResult(false, null, json.error ?? 'unknown error');
		}
	} catch (error) {
		console.log(error);
	}
	
	return new ApiResult(false, null, 'connection error');
}