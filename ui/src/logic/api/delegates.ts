import { BaseAPI } from "./base";
import { DelegateModelType } from "./../stores/delegates/delegate";

export class DelegatesApi extends BaseAPI {
  /**
   *
   * @param boothKey - booth key value
   */
  getDelegates = async (
    boothKey: string
  ): Promise<[DelegateModelType[] | null, any]> => {
    const scryUrl = `${this.baseUrl}/~/scry/ballot/booths/${boothKey}/delegates`;
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
      return [null, this.handleErrors(error)];
    }
  };

  /**
   *
   * @param boothKey - booth key value
   * @param delegateKey - patp of the ship to delegate to
   */
  addDelegate = async (boothKey: string, delegateKey: string) => {
    const scryUrl = `${this.baseUrl}/ballot/api/booths`;
    try {
      const response = await fetch(scryUrl, {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          action: "delegate",
          resource: "delegate",
          context: {
            booth: boothKey,
          },
          data: {
            delegate: delegateKey,
          },
        }),
      });

      return [await response.json(), null];
    } catch (error) {
      return [null, this.handleErrors(error)];
    }
  };

  /**
   *
   * @param boothKey - booth key value
   * @param delegateKey - patp of the ship to invite
   * @returns 200 on success w/ a string message in the body
   */
  deleteDelegate = async (boothKey: string, delegateKey: string) => {
    const scryUrl = `${this.baseUrl}/ballot/api/booths`;
    try {
      const response = await fetch(scryUrl, {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          action: "undelegate",
          resource: "delegate",
          context: {
            booth: boothKey,
          },
          data: {
            delegate: delegateKey,
          },
        }),
      });
      return [{ delegate: response }, null];
    } catch (error) {
      return [null, this.handleErrors(error)];
    }
  };
}

export default new DelegatesApi();
