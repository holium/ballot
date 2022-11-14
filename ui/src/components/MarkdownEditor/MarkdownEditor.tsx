import styled, { css } from "styled-components";
import type { ThemeType } from "@holium/design-system";

export interface MarkdownEditorProps {
  theme: ThemeType;
}

export const MarkdownEditor = styled.div`
  ${(props: MarkdownEditorProps) => css`
    .w-md-editor {
      color: ${props.theme.colors.text.primary};
      background-color: ${props.theme.colors.bg.secondary};
      box-shadow: ${props.theme.elevations.lifted};
      border-radius: 6px;
      /* border: 1px solid ${props.theme.colors.bg.divider}; */
      /* box-shadow: none; */
    }
    .w-md-editor-toolbar {
      background-color: ${props.theme.colors.bg.toolbar};
      border-radius: 6px 6px 0 0;
      border-bottom: 1px solid ${props.theme.colors.bg.divider};
    }
    .w-md-editor-preview {
      background-color: ${props.theme.colors.bg.secondary};
      border-radius: 0 0 6px 0;
      box-shadow: inset 1px 0 0 0 ${props.theme.colors.bg.divider} !important;
    }
    .w-md-editor-content {
      border-radius: 6px;
      color: inherit;
      background-color: inherit;
    }
    .w-md-editor-text {
      color: ${props.theme.colors.text.placeholder};
      -webkit-text-fill-color: ${props.theme.colors.text.primary} !important;
    }
    .w-md-editor-text-input:empty {
      color: ${props.theme.colors.text.placeholder};
      -webkit-text-fill-color: ${props.theme.colors.text
        .placeholder} !important;
    }
    .w-md-editor-toolbar-divider {
      background-color: ${props.theme.colors.bg.divider};
    }
    .w-md-editor-toolbar li > button {
      background-color: ${props.theme.colors.bg.toolbar};
      color: ${props.theme.colors.icon.toolbar};
      &:hover,
      &:active {
        background-color: ${props.theme.colors.ui.quaternary};
      }
    }
  `}
`;

// export const MarkdownEditor: FC<MarkdownEditorType> = (
//   props: MarkdownEditorType
// ) => {
//   const { content } = props;

//   return (
//     <MDEditor
//       style={{ fontFamily: "Inter, sans-serif" }}
//       height={500}
//       preview="edit"
//       value={content.state.value}
//       textareaProps={{
//         placeholder: "Explain more about your proposal",
//         onFocus: () => content.actions.onFocus(),
//         onBlur: () => content.actions.onBlur(),
//       }}
//       onChange={(value: string | undefined) => content.actions.onChange(value)}
//       previewOptions={{
//         rehypePlugins: [[rehypeSanitize]],
//         style: { fontFamily: "Inter, sans-serif" },
//       }}
//     />
//   );
// };
