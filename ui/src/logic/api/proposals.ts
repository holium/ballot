import BaseAPI from "./base";
import { ProposalType } from "../types/proposals";

export class ProposalsApi extends BaseAPI {
  /**
   *
   * create
   *
   * @param boothKey
   * @param proposal
   * @returns
   */
  async create(boothKey: string, proposal: any): Promise<[any, any]> {
    const url = `${this.baseUrl}/ballot/api/booths/${boothKey}`;
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        credentials: "include",
        body: JSON.stringify({
          action: "save-proposal",
          resource: "booth",
          key: boothKey,
          data: proposal,
        }),
      });
      return [await response.json(), null];
    } catch (error) {
      return [null, this.handleErrors(error)];
    }
  }
  /**
   *
   * update
   *
   * @param boothKey
   * @param proposalKey
   * @param proposal
   * @returns
   */
  async update(
    boothKey: string,
    proposalKey: string,
    proposal: Partial<ProposalType>
  ): Promise<[any, any]> {
    const url = `${this.baseUrl}/ballot/api/booths`;
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        credentials: "include",
        body: JSON.stringify({
          action: "save-proposal",
          resource: "booth",
          key: boothKey,
          data: { ...proposal, key: proposalKey },
        }),
      });
      return [await response.json(), null];
    } catch (error) {
      return [null, this.handleErrors(error)];
    }
  }
  /**
   *
   * getAll
   *
   * @param boothName
   * @returns
   */
  async getAll(boothName: string): Promise<[ProposalType[] | null, any]> {
    const scryUrl = `${this.baseUrl}/~/scry/ballot/booths/${boothName}/proposals`;
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
  }
  /**
   *
   * delete
   *
   * @param boothKey
   * @param proposalKey
   * @returns
   */
  async delete(boothKey: string, proposalKey: any): Promise<[any, any]> {
    const url = `${this.baseUrl}/ballot/api/booths/${boothKey}`;
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        credentials: "include",
        body: JSON.stringify({
          action: "delete-proposal",
          resource: "booth",
          key: proposalKey,
        }),
      });
      return [{ participant: response }, null];
    } catch (error) {
      return [null, this.handleErrors(error)];
    }
  }
}

export default new ProposalsApi();

// ---------------------------------------------------------------------------------------
