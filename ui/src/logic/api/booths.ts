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

  async getCustomActions(boothKey: string): Promise<any> {
    const scryUrl = `${this.baseUrl}/~/scry/ballot/booths/${boothKey}/custom-actions`;
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

  // /**
  //  *
  //  * @returns - array of booth objects
  //  */
  // async getAllVotes(): Promise<any> {
  //   const scryUrl = `${this.baseUrl}/~/scry/ballot/booths.json`;
  //   try {
  //     const response = await fetch(scryUrl, {
  //       method: "GET",
  //       credentials: "include",
  //       headers: {
  //         "Content-Type": "application/json",
  //       },
  //     });
  //     return [await response.json(), null];
  //   } catch (error) {
  //     return [this.handleErrors(error), null];
  //   }
  // }

  /**
   *
   * @param boothKey - booth key value
   * @param participant - patp of the ship to invite
   */
  saveBooth = async (boothKey: string, data: any) => {
    const scryUrl = `${this.baseUrl}/ballot/api/booths`;
    try {
      const response = await fetch(scryUrl, {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          action: "save-booth",
          resource: "booth",
          context: {
            booth: boothKey,
          },
          data,
        }), // ACTION TYPE
      });
      return [await response.json(), null];
    } catch (error) {
      return [null, this.handleErrors(error)];
    }
  };
  // /**
  //  *
  //  * @param boothKey - booth key value
  //  * @param participant - patp of the ship to invite
  //  */
  // join = async (boothKey: string) => {
  //   const scryUrl = `${this.baseUrl}/ballot/api/booths`;
  //   try {
  //     const response = await fetch(scryUrl, {
  //       method: "PUT",
  //       credentials: "include",
  //       headers: {
  //         "Content-Type": "application/json",
  //       },
  //       body: JSON.stringify({
  //         action: "join",
  //         resource: "booth",
  //         context: {
  //           booth: boothKey,
  //         },
  //       }), // ACTION TYPE
  //     });
  //     return [await response.json(), null];
  //   } catch (error) {
  //     return [null, this.handleErrors(error)];
  //   }
  // };

  /**
   *
   * @param boothKey - booth key value
   * @param participant - patp of the ship to invite
   */
  acceptInvite = async (boothKey: string) => {
    const scryUrl = `${this.baseUrl}/ballot/api/booths`;
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
          context: {
            booth: boothKey,
          },
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
