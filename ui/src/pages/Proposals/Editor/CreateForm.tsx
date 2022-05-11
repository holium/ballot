import { toJS } from "mobx";
import { createField, createForm } from "mobx-easy-form";
import { clone, unprotect } from "mobx-state-tree";
import * as yup from "yup";
import { ChoiceType } from "./Choices";

export const createProposalFormFields = (defaults: any = {}) => {
  const form = createForm({
    onSubmit({ values }) {
      values.redacted = false;
      values.start = Math.round(new Date(values.start).valueOf() / 1000);
      values.end = Math.round(new Date(values.end).valueOf() / 1000);
      return values;
    },
  });

  const title = createField({
    id: "title",
    form,
    initialValue: defaults.title || "",
    validationSchema: yup.string().required("Name is required"),
  });

  const content = createField({
    id: "content",
    form,
    initialValue: defaults.content || "",
    validationSchema: yup
      .string()
      .required("You should probably write something."),
  });

  const strategy = createField({
    id: "strategy",
    form,
    initialValue: defaults.strategy || "single-choice",
    validationSchema: yup.string().required("Strategy is required."),
  });

  const redactVotes = createField({
    id: "redacted",
    form,
    initialValue: defaults.redacted || "false",
  });

  const newStartTime = new Date();
  newStartTime.setHours(newStartTime.getHours() + 1);
  newStartTime.setMinutes(0);
  newStartTime.setSeconds(0);
  const newEndTime = new Date();
  newEndTime.setDate(newStartTime.getDate() + defaults.duration || 7);
  newEndTime.setHours(newStartTime.getHours());
  newEndTime.setMinutes(0);
  newEndTime.setSeconds(0);

  const startTime = createField({
    id: "start",
    form,
    initialValue: defaults.start
      ? new Date(defaults.start * 1000)
      : newStartTime,
    validationSchema: yup.date().required("Must have a start time."),
  });

  const endTime = createField({
    id: "end",
    form,
    initialValue: defaults.end ? new Date(defaults.end * 1000) : newEndTime,
    validationSchema: yup
      .date()
      .required("Must have an end time.")
      .when(
        "startTime",
        (startTime: any, schema: any) => startTime && schema.min(startTime)
      ),
  });

  const support = createField({
    id: "support",
    form,
    initialValue: defaults.support || "50",
    validationSchema: yup.number().required("Support is required."),
  });

  // const defaultChoices = defaults.choices && defaults.choices.slice();
  // const choices = createField({
  //   id: "choices",
  //   form,
  //   initialValue: defaultChoices || [
  //     { order: 1, label: "Approve", action: "approve-action" },
  //     { order: 2, label: "Reject", action: "reject-action" },
  //   ],
  //   validationSchema: yup.array().min(2, "Need at least two choices."),
  // });
  const defaultChoices =
    defaults.choices &&
    defaults.choices.map((choice: ChoiceType) => clone(choice, false));

  const choices = createField({
    id: "choices",
    form,
    initialValue: defaultChoices || [
      { label: "Approve", action: "approve-action" },
      { label: "Reject", action: "reject-action" },
    ],
    validationSchema: yup.array().min(2, "Need at least two choices."),
  });
  form.actions.add(choices);

  return {
    form,
    title,
    content,
    strategy,
    redactVotes,
    startTime,
    endTime,
    support,
    choices,
  };
};
