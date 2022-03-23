const baseUrl = import.meta.env.VITE_SHIP_URL?.toString()!;
export class BaseAPI {
  baseUrl: string = baseUrl;

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
