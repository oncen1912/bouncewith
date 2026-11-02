export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type Database = {
  public: {
    Tables: {
      ai_logs: {
        Row: {
          answer: string | null
          created_at: string
          handed_off: boolean
          id: number
          question: string
          user_id: string | null
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          answer?: string | null
          created_at?: string
          handed_off?: boolean
          id?: never
          question: string
          user_id?: string | null
          workspace_id: string
        }
        Update: {
          answer?: string | null
          created_at?: string
          handed_off?: boolean
          id?: never
          question?: string
          user_id?: string | null
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'ai_logs_user_id_fkey'
            columns: ['user_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'ai_logs_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      api_keys: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          key_hash: string
          last_used_at: string | null
          name: string
          prefix: string
          revoked_at: string | null
          scopes: string[]
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          key_hash: string
          last_used_at?: string | null
          name: string
          prefix: string
          revoked_at?: string | null
          scopes: string[]
          workspace_id: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          key_hash?: string
          last_used_at?: string | null
          name?: string
          prefix?: string
          revoked_at?: string | null
          scopes?: string[]
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'api_keys_created_by_fkey'
            columns: ['created_by']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'api_keys_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      attendance: {
        Row: {
          event_id: string
          marked_at: string
          marked_by: string | null
          method: Database['public']['Enums']['attendance_method']
          present: boolean
          user_id: string
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          event_id: string
          marked_at?: string
          marked_by?: string | null
          method?: Database['public']['Enums']['attendance_method']
          present: boolean
          user_id: string
          workspace_id: string
        }
        Update: {
          event_id?: string
          marked_at?: string
          marked_by?: string | null
          method?: Database['public']['Enums']['attendance_method']
          present?: boolean
          user_id?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'attendance_event_id_fkey'
            columns: ['event_id']
            isOneToOne: false
            referencedRelation: 'events'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'attendance_marked_by_fkey'
            columns: ['marked_by']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'attendance_user_id_fkey'
            columns: ['user_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'attendance_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      attendance_log: {
        Row: {
          changed_at: string
          changed_by: string | null
          event_id: string
          id: number
          new_present: boolean | null
          note: string | null
          old_present: boolean | null
          user_id: string
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          changed_at?: string
          changed_by?: string | null
          event_id: string
          id?: never
          new_present?: boolean | null
          note?: string | null
          old_present?: boolean | null
          user_id: string
          workspace_id: string
        }
        Update: {
          changed_at?: string
          changed_by?: string | null
          event_id?: string
          id?: never
          new_present?: boolean | null
          note?: string | null
          old_present?: boolean | null
          user_id?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'attendance_log_changed_by_fkey'
            columns: ['changed_by']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'attendance_log_event_id_fkey'
            columns: ['event_id']
            isOneToOne: false
            referencedRelation: 'events'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'attendance_log_user_id_fkey'
            columns: ['user_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'attendance_log_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      checkin_tokens: {
        Row: {
          created_by: string | null
          event_id: string
          expires_at: string
          id: string
          token_hash: string
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          created_by?: string | null
          event_id: string
          expires_at: string
          id?: string
          token_hash: string
          workspace_id: string
        }
        Update: {
          created_by?: string | null
          event_id?: string
          expires_at?: string
          id?: string
          token_hash?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'checkin_tokens_created_by_fkey'
            columns: ['created_by']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'checkin_tokens_event_id_fkey'
            columns: ['event_id']
            isOneToOne: false
            referencedRelation: 'events'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'checkin_tokens_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      conversations: {
        Row: {
          created_at: string
          event_id: string | null
          group_id: string | null
          id: string
          kind: Database['public']['Enums']['conversation_kind']
          member_id: string | null
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          created_at?: string
          event_id?: string | null
          group_id?: string | null
          id?: string
          kind: Database['public']['Enums']['conversation_kind']
          member_id?: string | null
          workspace_id: string
        }
        Update: {
          created_at?: string
          event_id?: string | null
          group_id?: string | null
          id?: string
          kind?: Database['public']['Enums']['conversation_kind']
          member_id?: string | null
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'conversations_event_id_fkey'
            columns: ['event_id']
            isOneToOne: false
            referencedRelation: 'events'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'conversations_group_id_fkey'
            columns: ['group_id']
            isOneToOne: false
            referencedRelation: 'groups'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'conversations_member_id_fkey'
            columns: ['member_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'conversations_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      event_series: {
        Row: {
          capacity: number | null
          category: string | null
          created_at: string
          created_by: string | null
          description: string
          duration_min: number
          group_ids: string[]
          id: string
          interval_weeks: number
          location: string | null
          start_time: string
          starts_on: string
          title: string
          until: string | null
          visibility: Database['public']['Enums']['event_visibility']
          weekdays: number[]
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          capacity?: number | null
          category?: string | null
          created_at?: string
          created_by?: string | null
          description?: string
          duration_min: number
          group_ids?: string[]
          id?: string
          interval_weeks?: number
          location?: string | null
          start_time: string
          starts_on: string
          title: string
          until?: string | null
          visibility?: Database['public']['Enums']['event_visibility']
          weekdays: number[]
          workspace_id: string
        }
        Update: {
          capacity?: number | null
          category?: string | null
          created_at?: string
          created_by?: string | null
          description?: string
          duration_min?: number
          group_ids?: string[]
          id?: string
          interval_weeks?: number
          location?: string | null
          start_time?: string
          starts_on?: string
          title?: string
          until?: string | null
          visibility?: Database['public']['Enums']['event_visibility']
          weekdays?: number[]
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'event_series_created_by_fkey'
            columns: ['created_by']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'event_series_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      events: {
        Row: {
          capacity: number | null
          category: string | null
          created_at: string
          created_by: string | null
          description: string
          ends_at: string
          external_id: string | null
          external_url: string | null
          group_ids: string[]
          id: string
          image_url: string | null
          location: string | null
          location_url: string | null
          rsvp_deadline: string | null
          series_id: string | null
          source: Database['public']['Enums']['event_source']
          starts_at: string
          status: Database['public']['Enums']['event_status']
          title: string
          updated_at: string
          visibility: Database['public']['Enums']['event_visibility']
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          capacity?: number | null
          category?: string | null
          created_at?: string
          created_by?: string | null
          description?: string
          ends_at: string
          external_id?: string | null
          external_url?: string | null
          group_ids?: string[]
          id?: string
          image_url?: string | null
          location?: string | null
          location_url?: string | null
          rsvp_deadline?: string | null
          series_id?: string | null
          source?: Database['public']['Enums']['event_source']
          starts_at: string
          status?: Database['public']['Enums']['event_status']
          title: string
          updated_at?: string
          visibility?: Database['public']['Enums']['event_visibility']
          workspace_id: string
        }
        Update: {
          capacity?: number | null
          category?: string | null
          created_at?: string
          created_by?: string | null
          description?: string
          ends_at?: string
          external_id?: string | null
          external_url?: string | null
          group_ids?: string[]
          id?: string
          image_url?: string | null
          location?: string | null
          location_url?: string | null
          rsvp_deadline?: string | null
          series_id?: string | null
          source?: Database['public']['Enums']['event_source']
          starts_at?: string
          status?: Database['public']['Enums']['event_status']
          title?: string
          updated_at?: string
          visibility?: Database['public']['Enums']['event_visibility']
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'events_created_by_fkey'
            columns: ['created_by']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'events_series_id_fkey'
            columns: ['series_id']
            isOneToOne: false
            referencedRelation: 'event_series'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'events_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      group_members: {
        Row: {
          group_id: string
          user_id: string
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          group_id: string
          user_id: string
          workspace_id: string
        }
        Update: {
          group_id?: string
          user_id?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'group_members_group_id_fkey'
            columns: ['group_id']
            isOneToOne: false
            referencedRelation: 'groups'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'group_members_group_same_ws'
            columns: ['group_id', 'workspace_id']
            isOneToOne: false
            referencedRelation: 'groups'
            referencedColumns: ['id', 'workspace_id']
          },
          {
            foreignKeyName: 'group_members_membership_fk'
            columns: ['workspace_id', 'user_id']
            isOneToOne: false
            referencedRelation: 'memberships'
            referencedColumns: ['workspace_id', 'user_id']
          },
          {
            foreignKeyName: 'group_members_user_id_fkey'
            columns: ['user_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'group_members_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      groups: {
        Row: {
          created_at: string
          id: string
          name: string
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          created_at?: string
          id?: string
          name: string
          workspace_id: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'groups_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      memberships: {
        Row: {
          joined_at: string
          role: Database['public']['Enums']['member_role']
          status: Database['public']['Enums']['membership_status']
          user_id: string
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          joined_at?: string
          role?: Database['public']['Enums']['member_role']
          status?: Database['public']['Enums']['membership_status']
          user_id: string
          workspace_id: string
        }
        Update: {
          joined_at?: string
          role?: Database['public']['Enums']['member_role']
          status?: Database['public']['Enums']['membership_status']
          user_id?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'memberships_user_id_fkey'
            columns: ['user_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'memberships_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      message_recipients: {
        Row: {
          emailed_at: string | null
          message_id: string
          pushed_at: string | null
          read_at: string | null
          user_id: string
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          emailed_at?: string | null
          message_id: string
          pushed_at?: string | null
          read_at?: string | null
          user_id: string
          workspace_id: string
        }
        Update: {
          emailed_at?: string | null
          message_id?: string
          pushed_at?: string | null
          read_at?: string | null
          user_id?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'message_recipients_message_id_fkey'
            columns: ['message_id']
            isOneToOne: false
            referencedRelation: 'messages'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'message_recipients_user_id_fkey'
            columns: ['user_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'message_recipients_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      messages: {
        Row: {
          audience: Json | null
          body: string
          conversation_id: string
          created_at: string
          deleted_at: string | null
          id: string
          reply_to: string | null
          sender_id: string | null
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          audience?: Json | null
          body: string
          conversation_id: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          reply_to?: string | null
          sender_id?: string | null
          workspace_id: string
        }
        Update: {
          audience?: Json | null
          body?: string
          conversation_id?: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          reply_to?: string | null
          sender_id?: string | null
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'messages_conversation_id_fkey'
            columns: ['conversation_id']
            isOneToOne: false
            referencedRelation: 'conversations'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'messages_reply_to_fkey'
            columns: ['reply_to']
            isOneToOne: false
            referencedRelation: 'messages'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'messages_sender_id_fkey'
            columns: ['sender_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'messages_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      pending_signups: {
        Row: {
          confirmed_at: string | null
          created_at: string
          email: string
          event_id: string | null
          expires_at: string
          full_name: string
          id: string
          origin: string | null
          token_hash: string
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          confirmed_at?: string | null
          created_at?: string
          email: string
          event_id?: string | null
          expires_at?: string
          full_name: string
          id?: string
          origin?: string | null
          token_hash: string
          workspace_id: string
        }
        Update: {
          confirmed_at?: string | null
          created_at?: string
          email?: string
          event_id?: string | null
          expires_at?: string
          full_name?: string
          id?: string
          origin?: string | null
          token_hash?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'pending_signups_event_id_fkey'
            columns: ['event_id']
            isOneToOne: false
            referencedRelation: 'events'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'pending_signups_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          created_at: string
          full_name: string
          id: string
          locale: string
          notify_email: boolean
          notify_push: boolean
        }
        ComputedFields: never
        Insert: {
          avatar_url?: string | null
          created_at?: string
          full_name?: string
          id: string
          locale?: string
          notify_email?: boolean
          notify_push?: boolean
        }
        Update: {
          avatar_url?: string | null
          created_at?: string
          full_name?: string
          id?: string
          locale?: string
          notify_email?: boolean
          notify_push?: boolean
        }
        Relationships: []
      }
      push_subscriptions: {
        Row: {
          auth: string
          created_at: string
          endpoint: string
          id: string
          p256dh: string
          user_agent: string | null
          user_id: string
        }
        ComputedFields: never
        Insert: {
          auth: string
          created_at?: string
          endpoint: string
          id?: string
          p256dh: string
          user_agent?: string | null
          user_id: string
        }
        Update: {
          auth?: string
          created_at?: string
          endpoint?: string
          id?: string
          p256dh?: string
          user_agent?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'push_subscriptions_user_id_fkey'
            columns: ['user_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
        ]
      }
      rsvps: {
        Row: {
          answer: Database['public']['Enums']['rsvp_answer']
          answered_at: string
          event_id: string
          reason: string | null
          user_id: string
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          answer: Database['public']['Enums']['rsvp_answer']
          answered_at?: string
          event_id: string
          reason?: string | null
          user_id: string
          workspace_id: string
        }
        Update: {
          answer?: Database['public']['Enums']['rsvp_answer']
          answered_at?: string
          event_id?: string
          reason?: string | null
          user_id?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'rsvps_event_id_fkey'
            columns: ['event_id']
            isOneToOne: false
            referencedRelation: 'events'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'rsvps_user_id_fkey'
            columns: ['user_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'rsvps_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      webhook_deliveries: {
        Row: {
          attempts: number
          created_at: string
          event_type: string
          id: number
          last_error: string | null
          next_attempt_at: string
          payload: NonNullable<Json>
          status: string
          webhook_id: string
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          attempts?: number
          created_at?: string
          event_type: string
          id?: never
          last_error?: string | null
          next_attempt_at?: string
          payload: NonNullable<Json>
          status?: string
          webhook_id: string
          workspace_id: string
        }
        Update: {
          attempts?: number
          created_at?: string
          event_type?: string
          id?: never
          last_error?: string | null
          next_attempt_at?: string
          payload?: NonNullable<Json>
          status?: string
          webhook_id?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'webhook_deliveries_webhook_id_fkey'
            columns: ['webhook_id']
            isOneToOne: false
            referencedRelation: 'webhooks'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'webhook_deliveries_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      webhooks: {
        Row: {
          active: boolean
          created_at: string
          event_types: string[]
          id: string
          secret: string
          url: string
          workspace_id: string
        }
        ComputedFields: never
        Insert: {
          active?: boolean
          created_at?: string
          event_types: string[]
          id?: string
          secret?: string
          url: string
          workspace_id: string
        }
        Update: {
          active?: boolean
          created_at?: string
          event_types?: string[]
          id?: string
          secret?: string
          url?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'webhooks_workspace_id_fkey'
            columns: ['workspace_id']
            isOneToOne: false
            referencedRelation: 'workspaces'
            referencedColumns: ['id']
          },
        ]
      }
      workspaces: {
        Row: {
          accent_color: string | null
          allow_self_absence: boolean
          allowed_origins: string[]
          created_at: string
          created_by: string | null
          faq_text: string
          id: string
          join_code: string
          logo_url: string | null
          name: string
          require_approval: boolean
          slug: string
          timezone: string
          type: Database['public']['Enums']['workspace_type']
        }
        ComputedFields: never
        Insert: {
          accent_color?: string | null
          allow_self_absence?: boolean
          allowed_origins?: string[]
          created_at?: string
          created_by?: string | null
          faq_text?: string
          id?: string
          join_code?: string
          logo_url?: string | null
          name: string
          require_approval?: boolean
          slug: string
          timezone?: string
          type?: Database['public']['Enums']['workspace_type']
        }
        Update: {
          accent_color?: string | null
          allow_self_absence?: boolean
          allowed_origins?: string[]
          created_at?: string
          created_by?: string | null
          faq_text?: string
          id?: string
          join_code?: string
          logo_url?: string | null
          name?: string
          require_approval?: boolean
          slug?: string
          timezone?: string
          type?: Database['public']['Enums']['workspace_type']
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      approve_member: { Args: { p_user: string; p_ws: string }; Returns: undefined }
      block_member: { Args: { p_user: string; p_ws: string }; Returns: undefined }
      can_see_conversation: { Args: { conv: string }; Returns: boolean }
      can_see_event: { Args: { ev: string }; Returns: boolean }
      create_workspace: {
        Args: {
          p_name: string
          p_slug: string
          p_timezone?: string
          p_type?: Database['public']['Enums']['workspace_type']
        }
        Returns: string
      }
      delete_my_account: { Args: { p_confirm_email: string }; Returns: undefined }
      in_any_group: { Args: { groups: string[] }; Returns: boolean }
      is_member: { Args: { ws: string }; Returns: boolean }
      is_owner: { Args: { ws: string }; Returns: boolean }
      is_trainer: { Args: { ws: string }; Returns: boolean }
      join_workspace: { Args: { p_code: string }; Returns: Database['public']['Enums']['membership_status'] }
      leave_workspace: { Args: { p_ws: string }; Returns: undefined }
      my_memberships: {
        Args: Record<PropertyKey, never>
        Returns: {
          accent_color: string
          is_last_owner: boolean
          logo_url: string
          name: string
          role: Database['public']['Enums']['member_role']
          slug: string
          status: Database['public']['Enums']['membership_status']
          timezone: string
          type: Database['public']['Enums']['workspace_type']
          workspace_id: string
        }[]
      }
      regenerate_join_code: { Args: { p_ws: string }; Returns: string }
      remove_member: { Args: { p_user: string; p_ws: string }; Returns: undefined }
      set_member_role: {
        Args: { p_role: Database['public']['Enums']['member_role']; p_user: string; p_ws: string }
        Returns: undefined
      }
      try_uuid: { Args: { value: string }; Returns: string }
      workspace_members: {
        Args: { p_ws: string }
        Returns: {
          avatar_url: string
          email: string
          full_name: string
          group_ids: string[]
          joined_at: string
          role: Database['public']['Enums']['member_role']
          status: Database['public']['Enums']['membership_status']
          user_id: string
        }[]
      }
      workspace_preview: {
        Args: { p_code: string }
        Returns: {
          accent_color: string
          logo_url: string
          my_status: Database['public']['Enums']['membership_status']
          name: string
          require_approval: boolean
          type: Database['public']['Enums']['workspace_type']
        }[]
      }
    }
    Enums: {
      attendance_method: 'trainer' | 'qr' | 'default'
      conversation_kind: 'broadcast' | 'event' | 'group' | 'direct'
      event_source: 'app' | 'api' | 'import'
      event_status: 'scheduled' | 'cancelled'
      event_visibility: 'members' | 'public'
      member_role: 'owner' | 'trainer' | 'member'
      membership_status: 'pending' | 'active' | 'blocked'
      rsvp_answer: 'going' | 'not_going'
      workspace_type: 'dance' | 'fitness' | 'yoga' | 'other'
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, 'public'>]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    keyof (DefaultSchema['Tables'] & DefaultSchema['Views']) | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Views'])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Views'])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema['Tables'] & DefaultSchema['Views'])
    ? (DefaultSchema['Tables'] & DefaultSchema['Views'])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    keyof DefaultSchema['Tables'] | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    keyof DefaultSchema['Tables'] | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    keyof DefaultSchema['Enums'] | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums']
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums'][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema['Enums']
    ? DefaultSchema['Enums'][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    keyof DefaultSchema['CompositeTypes'] | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes']
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes'][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema['CompositeTypes']
    ? DefaultSchema['CompositeTypes'][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      attendance_method: ['trainer', 'qr', 'default'],
      conversation_kind: ['broadcast', 'event', 'group', 'direct'],
      event_source: ['app', 'api', 'import'],
      event_status: ['scheduled', 'cancelled'],
      event_visibility: ['members', 'public'],
      member_role: ['owner', 'trainer', 'member'],
      membership_status: ['pending', 'active', 'blocked'],
      rsvp_answer: ['going', 'not_going'],
      workspace_type: ['dance', 'fitness', 'yoga', 'other'],
    },
  },
} as const
