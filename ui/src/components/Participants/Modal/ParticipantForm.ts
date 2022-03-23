import { createField, createForm } from "mobx-easy-form";
import { isValidPatp } from "urbit-ob";

export const createParticipantForm = () => {
  const form = createForm({
    onSubmit({ values }) {
      return values;
    },
  });
  const invitee = createField({
    id: "invitee",
    form,
    initialValue: "",
    validate: (patp: string) => {
      if (patp.length > 1 && isValidPatp(patp)) {
        return { error: undefined, parsed: patp };
      }

      return { error: "Invalid patp", parsed: undefined };
    },
  });

  return {
    form,
    invitee,
  };
};
