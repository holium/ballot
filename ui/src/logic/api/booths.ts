import BaseAPI from "./base";

export class BoothsApi extends BaseAPI {
  /**
   *
   * @returns - array of booth objects
   */
  async getAll(): Promise<any> {
    const scryUrl = `${this.baseUrl}/~/scry/ballot/booths.json`;
    try {
      const response = await fetch(scryUrl, {
        method: "GET",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
      });
      return [await response.json(), null];
    } catch (error) {
      return [this.handleErrors(error), null];
    }
  }

  /**
   *
   * @param boothKey - booth key value
   * @param participant - patp of the ship to invite
   */
  join = async (boothKey: string) => {
    const scryUrl = `${this.baseUrl}/ballot/api/booths`;
    try {
      const response = await fetch(scryUrl, {
        method: "PUT",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          action: "join",
          resource: "booth",
          key: boothKey,
        }), // ACTION TYPE
      });
      return [await response.json(), null];
    } catch (error) {
      return [null, this.handleErrors(error)];
    }
  };

  /**
   *
   * @param boothKey - booth key value
   * @param participant - patp of the ship to invite
   */
  acceptInvite = async (boothKey: string) => {
    const scryUrl = `${this.baseUrl}/ballot/api/booths/${boothKey}`;
    try {
      const response = await fetch(scryUrl, {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          action: "accept",
          resource: "booth",
          key: boothKey,
        }),
      });
      return [await response.json(), null];
    } catch (error) {
      return [null, this.handleErrors(error)];
    }
  };

  leave = () => {};

  kick = () => {};
}

export default new BoothsApi();
