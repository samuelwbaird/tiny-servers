import * as h from '../js/hair-mini.js';

export const IDENTITY_UNKNOWN = 0;
export const IDENTITY_SIGNING_IN = 1;
export const IDENTITY_SIGNED_IN = 2;

export function identityStatus() {
	return IDENTITY_UNKNOWN;
}

export async function call(server, api_name, parameters) {
	return await _http_api_request('../' + server + '/api/' + api_name);
}

export class ApiResult {
	constructor (success, data, error) {
		this.success = success;
		this.data = data;
		this.error = error;
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