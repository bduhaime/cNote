const token = import.meta.env.VITE_DEV_JWT;

export async function apiFetch( url, options = {} ) {

  const headers = {
	 ...( options.headers ?? {} ),
	 Authorization: `Bearer ${token}`
  };

  return fetch( url, {
	 ...options,
	 headers
  });

}
