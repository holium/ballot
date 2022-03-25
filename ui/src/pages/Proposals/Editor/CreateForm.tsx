import { createField, createForm } from "mobx-easy-form";
import * as yup from "yup";

export const createProposalForm = () => {
  // const proposalBooth = booth?.name;
  const form = createForm({
    onSubmit({ values }) {
      values.start = new Date(values.start).valueOf();
      values.end = new Date(values.end).valueOf();
      values.status = "draft";
      return values;
    },
  });

  return {
    form,
  };
};

export const createProposalFormFields = (defaults: any = {}) => {
  const form = createForm({
    onSubmit({ values }) {
      values.redacted = Boolean(values.redacted);
      values.start = new Date(values.start).valueOf();
      values.end = new Date(values.end).valueOf();
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
  newStartTime.setHours(0);
  newStartTime.setMinutes(0);
  newStartTime.setSeconds(0);
  const newEndTime = new Date();
  newEndTime.setDate(newStartTime.getDate() + 7);
  newEndTime.setHours(0);
  newEndTime.setMinutes(0);
  newEndTime.setSeconds(0);

  const startTime = createField({
    id: "start",
    form,
    initialValue: defaults.start ? new Date(defaults.start) : newStartTime,
    validationSchema: yup.date().required("Must have a start time."),
  });

  const endTime = createField({
    id: "end",
    form,
    initialValue: defaults.end ? new Date(defaults.end) : newEndTime,
    validationSchema: yup.date().required("Must have an end time."),
  });

  const support = createField({
    id: "support",
    form,
    initialValue: defaults.support || "50",
    validationSchema: yup.number().required("Support is required."),
  });

  const choices = createField({
    id: "choices",
    form,
    initialValue: defaults.choices || [
      { order: 1, label: "Approve", action: "approve-action" },
      { order: 2, label: "Reject", action: "reject-action" },
    ],
    validationSchema: yup.array().min(2, "Need at least two choices."),
  });

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

export const addFields = (form: any, defaults: any = {}) => {
  const title = createField({
    id: "title",
    form,
    initialValue: defaults.title || "",
    validationSchema: yup.string().required("Name is required"),
  });
  form.actions.add(title);

  const content = createField({
    id: "content",
    form,
    initialValue: defaults.content || "",
    validationSchema: yup
      .string()
      .required("You should probably write something."),
  });
  form.actions.add(content);

  const strategy = createField({
    id: "strategy",
    form,
    initialValue: defaults.strategy || "single-choice",
    validationSchema: yup.string().required("Strategy is required."),
  });
  form.actions.add(strategy);

  const redactVotes = createField({
    id: "redacted",
    form,
    initialValue: defaults.redacted || "false",
  });
  form.actions.add(redactVotes);

  const startTime = createField({
    id: "start",
    form,
    initialValue: defaults.start || "",
    validationSchema: yup.date().required("Must have a start time."),
  });
  form.actions.add(startTime);

  const endTime = createField({
    id: "end",
    form,
    initialValue: defaults.end || "",
    validationSchema: yup.date().required("Must have an end time."),
  });
  form.actions.add(endTime);

  const support = createField({
    id: "support",
    form,
    initialValue: defaults.support || "50",
    validationSchema: yup.number().required("Support is required."),
  });
  form.actions.add(support);

  const choices = createField({
    id: "choices",
    form,
    initialValue: defaults.choices || [
      { order: 1, label: "Approve", action: "approve-action" },
      { order: 2, label: "Reject", action: "reject-action" },
    ],
    validationSchema: yup.array().min(2, "Need at least two choices."),
  });
  form.actions.add(choices);

  return {
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
