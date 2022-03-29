const baseUrl = import.meta.env.VITE_SHIP_URL?.toString()!;
export class BaseAPI {
  baseUrl: string = baseUrl;

  authCookie: string = document.cookie
    .split(";")
    .find((cookie: string) => cookie.includes(window.ship))!;

  // request = ({ }) => {

  // }

  handleErrors = (error: any) => {
    if (error) {
      console.log(error);
      return error.message;
    }
  };
}

export default BaseAPI;
