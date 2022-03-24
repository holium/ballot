import { BaseAPI } from "./base";
import { ParticipantType } from "../types/participants";
export class ParticipantsApi extends BaseAPI {
  /**
   *
   * @param boothKey - booth key value
   */
  getParticipants = async (
    boothKey: string
  ): Promise<[ParticipantType[] | null, any]> => {
    const scryUrl = `${this.baseUrl}/~/scry/ballot/booths/${boothKey}/participants`;
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
   * @param participant - patp of the ship to invite
   */
  addParticipant = async (boothKey: string, participant: string) => {
    const scryUrl = `${this.baseUrl}/ballot/api/booths/${boothKey}`;
    try {
      const response = await fetch(scryUrl, {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          action: "invite",
          resource: "booth",
          key: boothKey,
          data: { key: participant },
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
   * @param participantKey - patp of the ship to invite
   * @returns 200 on success w/ a string message in the body
   */
  deleteParticipant = async (boothKey: string, participantKey: string) => {
    const scryUrl = `${this.baseUrl}/ballot/api/booths/${boothKey}/participants/${participantKey}`;
    try {
      const response = await fetch(scryUrl, {
        method: "DELETE",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
      });
      return [{ participant: response }, null];
    } catch (error) {
      return [null, this.handleErrors(error)];
    }
  };
}

export default new ParticipantsApi();
