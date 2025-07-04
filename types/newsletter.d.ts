// Enhanced TypeScript types for newsletter system v5.0

export interface Newsletter {
  id: number;
  title: string;
  slug: string;
  category:
    | "company"
    | "product"
    | "weekly"
    | "monthly"
    | "event"
    | "offer"
    | "story";
  tags: string[];
  template_id?: number;
  subject_line: string;
  preview_text?: string;
  from_name: string;
  from_email: string;
  reply_to?: string;
  status: "draft" | "ready" | "scheduled" | "sending" | "sent" | "paused";
  priority: "low" | "normal" | "high" | "urgent";
  scheduled_send_date?: string;
  is_ab_test: boolean;
  ab_test_percentage?: number;
  ab_test_subject_b?: string;
  open_rate?: number;
  click_rate?: number;
  total_opens: number;
  approval_status: "pending" | "approved" | "rejected" | "changes_requested";
  approval_notes?: string;
  mailing_list_id?: number;
  test_emails: string[];
  compiled_mjml?: string;
  compiled_html?: string;
  blocks?: NewsletterBlock[];
}

export interface NewsletterBlock {
  id: number;
  newsletter_id: number;
  block_type: BlockType;
  sort: number;
  title?: string;
  subtitle?: string;
  text_content?: string;
  image_url?: string;
  image_alt_text?: string;
  image_caption?: string;
  button_text?: string;
  button_url?: string;
  background_color: string;
  text_color: string;
  text_align: "left" | "center" | "right";
  padding: string;
  font_size: string;
  content?: Record<string, any>; // Legacy field
  mjml_output?: string;
}

export interface BlockType {
  id: number;
  name: string;
  slug: string;
  description: string;
  mjml_template: string;
  status: "published" | "draft" | "archived";
  field_visibility_config?: string[];
  icon?: string;
  category: "content" | "layout" | "media" | "interactive";
}

export interface NewsletterTemplate {
  id: number;
  name: string;
  description: string;
  category: string;
  thumbnail_url?: string;
  blocks_config: Record<string, any>;
  default_subject_pattern?: string;
  default_from_name?: string;
  default_from_email?: string;
  status: "published" | "draft";
  usage_count: number;
  tags: string[];
}

export interface ContentLibrary {
  id: number;
  title: string;
  content_type:
    | "text"
    | "hero"
    | "button"
    | "image"
    | "html"
    | "social"
    | "footer";
  content_data: Record<string, any>;
  preview_text?: string;
  tags: string[];
  category: string;
  usage_count: number;
  is_global: boolean;
}

export interface Subscriber {
  id: number;
  email: string;
  name: string;
  first_name?: string;
  last_name?: string;
  company?: string;
  job_title?: string;
  status: "active" | "unsubscribed" | "bounced" | "pending" | "suppressed";
  subscription_source:
    | "website"
    | "import"
    | "manual"
    | "event"
    | "api"
    | "referral";
  subscription_preferences: string[];
  custom_fields?: Record<string, any>;
  engagement_score: number;
  subscribed_at: string;
  last_email_opened?: string;
  unsubscribe_token: string;
}

export interface MailingList {
  id: number;
  name: string;
  description?: string;
  category: string;
  tags: string[];
  subscriber_count: number;
  active_subscriber_count: number;
  status: "active" | "inactive" | "archived";
  double_opt_in: boolean;
  subscribers?: Subscriber[];
}

export interface NewsletterSend {
  id: number;
  newsletter_id: number;
  mailing_list_id: number;
  status: "pending" | "sending" | "sent" | "failed" | "paused";
  send_type: "regular" | "test" | "ab_test_a" | "ab_test_b";
  total_recipients: number;
  sent_count: number;
  failed_count: number;
  open_count: number;
  click_count: number;
  open_rate?: number;
  delivery_rate?: number;
  error_log?: string;
  sent_at?: string;
}
